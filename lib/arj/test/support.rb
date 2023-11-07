# frozen_string_literal: true

require 'active_job'
require 'active_job/base'
require_relative '../persistence'
require_relative '../query'

module Arj
  # Arj testing module. Provides job classes for use in tests.
  #
  # See:
  # - {Job}              - A test job.
  # - {Error}            - A test error which, when raised from a test job, will cause the job to be retried.
  # - {JobWithShard}     - A test job with an added +shard+ column.
  # - {JobWithLastError} - A test job with an added +last_error+ column.
  module Test
    include Query

    # Overrides {Query::ClassMethods.all} to provide a scope for test jobs.
    #
    # Example usage:
    #   Arj::Test::Job.perform_later
    #
    #   Arj::Test.available.first            # Returns next available test job
    #   Arj::Test.where(executions: 0).count # Returns the number of test jobs which have never been executed.
    #
    # @return [Arj::Relation]
    def self.all
      Arj.where(job_class: [Job].map(&:name))
    end

    # A test error which, when raised from a test job, will cause the job to be retried.
    class Error < StandardError; end

    # A test job which does one of the following:
    # - If the first argument is an +Exception+, raises it, using the second argument (if given) as the message.
    # - If the first argument is a +Proc+, invokes it and returns the result.
    # - Otherwise, returns the specified argument(s).
    #
    # Example usage:
    #   # Do nothing
    #   job = Arj::Test::Job.perform_later('some arg')
    #   job.perform_now # returns nil
    #
    #   # Return a value
    #   job = Arj::Test::Job.perform_later('some arg')
    #   job.perform_now # returns 'some arg'
    #
    #   # Return multiple values
    #   job = Arj::Test::Job.perform_later('some arg', 'other arg')
    #   job.perform_now # returns ['some arg', 'other arg']
    #
    #   # Raise an error
    #   job = Arj::Test::Job.perform_later(StandardError)
    #   job.perform_now # raises StandardError.new
    #
    #   # Raise an error with a message
    #   job = Arj::Test::Job.perform_later(StandardError, 'oh, hi')
    #   job.perform_now # raises StandardError.new('oh, hi')
    #
    #   # Cause a retry
    #   job = Arj::Test::JobWithRetry.perform_later(Arj::Test::Error)
    #   job.perform_now # re-enqueues and returns an Arj::Test::Error
    #
    #   # Override perform
    #   job = Arj::Test::Job.perform_later(-> { 'some val' })
    #   job.perform_now # returns 'some val'
    #   job.on_perform { 'other val' }
    #   job.perform_now # returns 'other val'
    class Job < ActiveJob::Base
      retry_on Arj::Test::Error, wait: 1.minute, attempts: 2

      include Query
      include Persistence

      @on_perform = {}
      @global_executions = {}
      class << self
        # Mapping of job ID to +Proc+ invoked in +perform+. Set by specifying a +Proc+ as the first argument.
        #
        # Update via {.on_perform}.
        #
        # @return [Hash]
        attr_accessor :on_perform

        # Mapping of job ID to execution count. Used to retrieve the execution count for a job, even if it has been
        # deleted or from an instance which has not been reloaded from the database.
        #
        # @return [Hash]
        attr_accessor :global_executions

        # Overridden to add support for +Proc+ arguments.
        #
        # @return [Arj::Test::Job, FalseClass]
        def perform_later(*args, **kwargs, &)
          proc = args[0].is_a?(Proc) ? args.shift : nil
          super(*args, **kwargs, &).tap { |job| Job.on_perform[job.job_id] = proc if proc }
        end

        # Returns the total number of executions across all jobs.
        #
        # @return [Integer]
        def total_executions
          Job.global_executions.values.sum
        end

        # Clears {.on_perform}.
        #
        # @return [NilClass]
        def reset
          Job.on_perform.clear
          Job.global_executions.clear
          nil
        end
      end

      # Does one of the following:
      # - If the first argument is an +Exception+, raises it, using the second argument (if given) as the message.
      # - If the first argument is a +Proc+, invokes it and returns the result.
      # - Otherwise, returns the specified argument or arguments, or +nil+ if none were specified.
      def perform(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
        Job.global_executions[job_id] = (Job.global_executions[job_id] || 0) + 1
        return Job.on_perform[job_id].call if Job.on_perform[job_id]

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

      # Sets a +Proc+ which will be invoked by {#perform}.
      #
      # @return [NilClass]
      def on_perform(&block)
        Job.on_perform[job_id] = block
        nil
      end

      # Returns the total number of executions for this job, even if this instance has not been reloaded from the
      # database. Useful, for instance when a job has been deleted and only a reference to the original job exists.
      #
      # @return [Integer]
      def global_executions
        Job.global_executions[job_id] || 0
      end
    end

    # A {Job} with a +shard+ attribute. See: {Arj::Extensions::Shard}.
    class JobWithShard < Arj::Test::Job
      include Arj::Extensions::Shard
    end

    # A {Job} with a +last_error+ attribute. See: {Arj::Extensions::LastError}.
    class JobWithLastError < Arj::Test::Job
      include Arj::Extensions::LastError
    end
  end
end
