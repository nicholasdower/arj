# frozen_string_literal: true

require 'timeout'

module Arj
  module Extensions
    # Adds timeout support to a job class.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Extensions::Timeout
    #
    #     timeout_after(1.second)
    #
    #     def perform
    #       sleep 2
    #     end
    #   end
    #
    #   job = SampleJob.perform_later
    #   job.perform_now
    #
    # Optionally, the default timeout may be changed:
    #
    #   Arj::Extensions::Timeout.default_timeout = 5.seconds
    #
    # Optionally, the timeout can be customized for a job class:
    #
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Extensions::Timeout
    #
    #     timeout_after(5.seconds)
    #   end
    module Timeout
      @default_timeout = 5.minutes

      class << self
        # The default maximum amount of time a job may run before being terminated.
        #
        # @return [ActiveSupport::Duration]
        attr_accessor :default_timeout
      end

      # Exception raised when a job times out.
      class Error < StandardError; end

      # Class methods added to jobs which include {Arj::Extensions::Timeout}.
      module ClassMethods
        # Sets the maximum amount of time jobs of this type may execute before being terminated. Overrides the global
        # default {Arj::Timeout.default_timeout}.
        #
        # @param duration [Duration, NilClass]
        # @return [Duration]
        def timeout_after(duration)
          @__arj_timeout = duration
        end
      end

      # Extends the specified class with {Arj::Timeout::ClassMethods} and registers an +around_perform+ callback used
      # to enforce timeouts.
      #
      # @param clazz [Class]
      # @return [Class]
      def self.included(clazz)
        clazz.around_perform do |job, block|
          timeout = job.class.instance_variable_get(:@__arj_timeout)
          timeout ||= Arj::Extensions::Timeout.default_timeout
          ::Timeout.timeout(timeout.in_seconds, Arj::Extensions::Timeout::Error, 'execution expired') { block.call }
        end
        clazz.extend(Arj::Extensions::Timeout::ClassMethods)
      end
    end
  end
end
