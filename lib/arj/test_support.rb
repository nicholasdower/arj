# frozen_string_literal: true

require 'active_job/base'
require_relative 'persistence'
require_relative 'query_methods'

module Arj
  # Arj testing module. Provides job classes for use in tests.
  #
  # See:
  # - {Error} - A test error which, when raised from {JobWithRetry}, will cause the job to be retried.
  # - {Base} - The base class for test jobs.
  # - {Job} - A test job.
  # - {JobWithPersistence} - A {Job} which includes the {Persistence} module.
  # - {JobWithQuery} - A {Job} which includes the {Query} module.
  # - {JobWithRetry} - A {Job} which retries on {Error}.
  module Test
    # A test error which, when raised from {JobWithRetry}, will cause the job to be retried.
    class Error < StandardError; end

    # The base class for test jobs.
    #
    # Subclasses:
    # - {Job}
    # - {JobWithPersistence}
    # - {JobWithQuery}
    # - {JobWithRetry}
    class Base < ActiveJob::Base
      # Returns the specified argument(s) or raises if an error class is specified.
      #
      # Example usage:
      #   job = Arj::Test::Job.perform_later('some arg')
      #   job.perform_now
      #
      #   job = Arj::Test::Job.perform_later(StandardError)
      #   job.perform_now
      #
      #   job = Arj::Test::Job.perform_later(StandardError, 'oh, hi')
      #   job.perform_now
      #
      # @raise the first arguments, if it is an Exception
      # @return [Array, Object, NilClass]
      def perform(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
        raise(args[0], args[1] || 'error') if args[0].is_a?(Class) && args[0] < Exception

        case arguments.size
        when 0
          nil
        when 1
          arguments.sole
        else
          arguments
        end
      end
    end

    # A test job.
    #
    # Example usage:
    #   job = Arj::Test::Job.perform_later('some arg')
    #   job.perform_now
    #
    #   job = Arj::Test::Job.perform_later(StandardError)
    #   job.perform_now
    #
    #   job = Arj::Test::Job.perform_later(StandardError, 'oh, hi')
    #   job.perform_now
    class Job < Base; end

    # A {Job} which includes the {Persistence} module.
    #
    # Example usage:
    #   job = Arj::Test::JobWithPersistence.perform_later('some arg')
    #   job.update!(queue_name: 'some queue')
    class JobWithPersistence < Job
      include Persistence
    end

    # A {Job} which includes the {Query} module.
    #
    # Example usage:
    #   Arj::Test::JobWithQuery.set(queue_name: 'some queue').perform_later('some arg')
    #   job = job.where(queue_name: 'some queue').first
    #   job.perform_now
    class JobWithQuery < Job
      include QueryMethods
    end

    # A {Job} which retries on {Error}.
    #
    # Example usage:
    #   job = Arj::Test::JobWithRetry.perform_later(Arj::Test::Error)
    #   job.perform_now
    #
    #   job = Arj::Test::JobWithRetry.perform_later(Arj::Test::Error, 'oh, hi')
    #   job.perform_now
    class JobWithRetry < Job
      retry_on Arj::Test::Error, wait: 1.minute, attempts: 2
    end
  end
end
