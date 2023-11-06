# frozen_string_literal: true

require 'active_job'
require 'active_job/arguments'
require 'active_record'
require 'json'
require_relative '../arj'

module Arj
  # ActiveRecord-style persistence methods (+save!+, +update!+, +exists?+, etc.), but for jobs.
  #
  # Example usage
  #   class SampleJob < ActiveJob::Base
  #     include Arj::Persistence
  #   end
  #
  #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
  #   job.queue_name = 'other queue'
  #   job.save!
  #
  # The {Arj} module provides the same methods but with a job argument.
  #
  # Example usage:
  #   class SampleJob < ActiveJob::Base; end
  #
  #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
  #   job.queue_name = 'other queue'
  #   Arj.save!(job)
  module Persistence
    REQUIRED_JOB_ATTRIBUTES = %w[
      job_class job_id provider_job_id queue_name
      priority arguments executions exception_executions
      locale timezone enqueued_at scheduled_at
    ].freeze
    private_constant :REQUIRED_JOB_ATTRIBUTES

    REQUIRED_RECORD_ATTRIBUTES = %w[
      job_class job_id queue_name priority arguments executions
      exception_executions locale timezone enqueued_at scheduled_at
    ].freeze
    private_constant :REQUIRED_RECORD_ATTRIBUTES

    class << self
      # Enqueues a job, optionally at the specified time.
      #
      # @param job [ActiveJob::Base] the job to enqueue
      # @param timestamp [Numeric, NilClass] optional number of seconds since Unix epoch at which to execute the job
      # @return [ActiveJob::Base] the enqueued job
      def enqueue(job, timestamp = nil)
        job.scheduled_at = timestamp ? Time.zone.at(timestamp) : nil

        if job.provider_job_id
          record = Arj.record_class.find(job.provider_job_id)
          record.update!(Persistence.record_attributes(job))
        else
          record = Arj.record_class.create!(Persistence.record_attributes(job))
        end
        Persistence.from_record(record, job)

        job
      end

      # Returns a job object for the specified database record. If a job is specified, it is updated from the record.
      #
      # @return [ActiveJob::Base]
      def from_record(record, job = nil)
        raise "expected #{Arj.record_class}, found #{record.class}" unless record.is_a?(Arj.record_class)
        raise "expected #{record.job_class}, found #{job.class}" if job && job.class.name != record.job_class

        job ||= Object.const_get(record.job_class).new
        raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

        if job.provider_job_id && job.provider_job_id != record.id
          raise ArgumentError, "unexpected id for #{job.class}: #{record.id} vs. #{job.provider_job_id}"
        end

        job.successfully_enqueued = true
        job_data = job_data(record)

        # ActiveJob deserializes arguments on demand when a job is performed. Until then they are empty. That's strange.
        job.arguments = ActiveJob::Arguments.deserialize(job_data['arguments'])
        job.deserialize(job_data)
        job.singleton_class.prepend(Arj::Job) unless job.singleton_class < Arj::Job

        job
      end

      # Returns serialized job data for the specified database record.
      #
      # @return [Hash]
      def job_data(record)
        record.attributes.fetch_values(*REQUIRED_RECORD_ATTRIBUTES)
        job_data = record.attributes
        job_data['arguments'] = JSON.parse(job_data['arguments'])
        job_data['provider_job_id'] = record.id
        job_data['exception_executions'] = JSON.parse(job_data['exception_executions'])
        job_data['enqueued_at'] = job_data['enqueued_at'].iso8601
        job_data['scheduled_at'] = job_data['scheduled_at']&.iso8601 if job_data['scheduled_at']
        job_data
      end

      # Returns database record attributes for the specified job.
      #
      # @return [Hash]
      def record_attributes(job)
        serialized = job.serialize
        serialized.fetch_values(*REQUIRED_JOB_ATTRIBUTES)
        serialized.delete('provider_job_id')
        serialized['arguments'] = serialized['arguments'].to_json
        serialized['exception_executions'] = serialized['exception_executions'].to_json
        serialized.symbolize_keys
      end
    end

    # @return [Boolean] +true+ if this has a corresponding record in the database
    def exists?
      Arj.exists?(self)
    end

    # Reloads the attributes of this job from the database.
    #
    # @return [ActiveJob::Base] the specified job, updated
    def reload
      Arj.reload(self)
    end

    # Saves the database record associated with this job. Raises if the record is invalid.
    #
    # @return [Boolean] +true+
    def save!
      Arj.save!(self)
    end

    # Updates the database record associated with this job. Raises if the record is invalid.
    #
    # @return [Boolean] +true+
    def update!(attributes)
      Arj.update!(self, attributes)
    end

    # Destroys the database record associated with this job.
    #
    # @return [ActiveJob::Base] the specified job
    def destroy!
      Arj.destroy!(self)
    end

    # @return [Boolean] +true+ if the this job has been deleted from the database
    def destroyed?
      Arj.destroyed?(self)
    end
  end
end
