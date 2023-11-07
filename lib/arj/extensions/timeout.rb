# frozen_string_literal: true

require 'timeout'

module Arj
  module Timeout
    DEFAULT_DEFAULT_TIMEOUT = 5.minutes
    private_constant :DEFAULT_DEFAULT_TIMEOUT

    @default_timeout = DEFAULT_DEFAULT_TIMEOUT

    class << self
      # The default maximum amount of time a job may run before being terminated.
      #
      # @type [ActiveSupport::Duration]
      attr_accessor :default_timeout
    end

    class Error < StandardError; end

    module Job
      module ClassMethods
        def timeout_after(duration)
          @timeout = duration
        end

        def timeout
          @timeout || Arj::Timeout.default_timeout
        end
      end

      def perform_now
        ::Timeout.timeout(self.class.timeout.in_seconds, Error) { super }
      end
    end
  end

  module Extensions
    module Timeout
      # Prepends {Arj::Timeout::Job} when this module is included.
      #
      # @param clazz [Class]
      # @return [Class]
      def self.included(clazz)
        raise "expected an ActiveJob::Base, found: #{clazz}" unless clazz < ActiveJob::Base

        clazz.prepend(Arj::Timeout::Job)
        clazz.extend(Arj::Timeout::Job::ClassMethods)
      end
    end
  end
end
