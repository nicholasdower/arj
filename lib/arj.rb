# frozen_string_literal: true

require 'active_record'
require_relative 'arj/arj_adapter'
require_relative 'arj/documentation'
require_relative 'arj/extensions'
require_relative 'arj/job'
require_relative 'arj/record'
require_relative 'arj/relation'
require_relative 'arj/version'
require_relative 'arj/worker'

# Arj. An ActiveJob queuing backend which uses ActiveRecord.
#
# For more information about Arj, see: https://github.com/nicholasdower/arj.
#
# The Arj module provides:
# - Access to the global Arj setting {record_class}.
# - Job query methods via {Arj::Extensions::Query}.
# - Job persistence methods similar to {Arj::Extensions::Persistence}.
module Arj
  REQUIRED_JOB_ATTRIBUTES = %w[
    job_class job_id queue_name priority arguments executions
    exception_executions locale timezone enqueued_at scheduled_at
  ].freeze
  private_constant :REQUIRED_JOB_ATTRIBUTES

  REQUIRED_RECORD_ATTRIBUTES = %w[
    job_class job_id queue_name priority arguments executions
    exception_executions locale timezone enqueued_at scheduled_at
  ].freeze
  private_constant :REQUIRED_RECORD_ATTRIBUTES

  DEFAULT_RECORD_CLASS = 'Job'
  private_constant :DEFAULT_RECORD_CLASS

  @record_class = DEFAULT_RECORD_CLASS

  include Arj::Extensions::Query

  class << self
    include Arj::Documentation::ActiveRecordRelation
    include Arj::Documentation::ArjRecord

    # The Class used to interact with jobs in the database. Defaults to +Job+.
    #
    # Note that if set to a String, will be lazily constantized.
    #
    # @return [Class]
    # @!attribute [rw] record_class
    def record_class
      @record_class = @record_class.constantize if @record_class.is_a?(String)
      @record_class
    end

    def record_class=(clazz)
      raise ArgumentError, "invalid class: #{clazz || 'nil'}" unless clazz.is_a?(Class) || clazz.is_a?(String)

      @record_class = clazz
    end

    # @param job [ActiveJob::Base]
    # @return [Boolean] +true+ if the specified job has a corresponding record in the database
    def job_exists?(job)
      Arj.record_class.exists?(job.job_id)
    end

    # Reloads the attributes of the specified job from the database.
    #
    # @param job [ActiveJob::Base]
    # @return [ActiveJob::Base] the specified job, updated
    def reload_job(job)
      record = Arj.record_class.find(job.job_id)
      Arj.from(record, job)
      job
    rescue ActiveRecord::RecordNotFound
      job.successfully_enqueued = false
      raise
    end

    # Saves the database record associated with the specified job. Raises if the record is invalid.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Job
    #   end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   job.queue_name = 'other queue'
    #   Arj.save_job!(job)
    #
    # @param job [ActiveJob::Base]
    # @return [Boolean] +true+
    def save_job!(job)
      if (record = Arj.record_class.find_by(job_id: job.job_id))
        record.update!(record_attributes(job)).tap { Arj.from(record, job) }
      else
        Arj.record_class.new(record_attributes(job)).save!
      end
    end

    # Updates the database record associated with the specified job. Raises if the record is invalid.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Job
    #   end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   Arj.update_job!(job, queue_name: 'other queue')
    #
    # @param job [ActiveJob::Base]
    # @param attributes [Hash]
    # @return [Boolean] +true+
    def update_job!(job, attributes)
      raise "invalid attributes: #{attributes}" unless attributes.is_a?(Hash)

      job_id = job.job_id
      attributes.each { |k, v| job.send("#{k}=".to_sym, v) }
      record = Arj.record_class.find(job_id)
      record.update!(record_attributes(job))
    end

    # Destroys the database record associated with the specified job.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Job
    #   end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   Arj.destroy_job!(job)
    #
    # @param job [ActiveJob::Base]
    # @return [ActiveJob::Base] the specified job
    def destroy_job!(job)
      record = Arj.record_class.find(job.job_id)
      record.destroy!
      job.successfully_enqueued = false
      job.scheduled_at = nil
      job.enqueued_at = nil
      job
    end

    # @param job [ActiveJob::Base]
    # @return [Boolean] +true+ if the specified job has been deleted from the database
    def job_destroyed?(job)
      !job_exists?(job)
    end

    # Returns a job object for the specified database record. If a job is specified, it is updated from the record.
    #
    # @param record [ActiveRecord::Base]
    # @param job [ActiveJob::Base]
    # @return [ActiveJob::Base]
    def from(record, job = nil)
      raise "expected #{Arj.record_class}, found #{record.class}" unless record.is_a?(Arj.record_class)
      raise "expected #{record.job_class}, found #{job.class}" if job && job.class.name != record.job_class

      record_id = record.attributes['id'] # Nil if the database does not have an ID column

      # If the job has been enqueued or has a provider id, the provider id should equal the record id
      if job&.provider_job_id && job.provider_job_id != record_id
        raise ArgumentError, "unexpected id for #{job.class}: #{record_id || 'nil'} vs. #{job.provider_job_id}"
      end

      job ||= Object.const_get(record.job_class).new
      raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

      job_data = Arj.job_data(record)

      job.deserialize(job_data)

      # ActiveJob deserializes arguments on demand when a job is performed. Until then they are empty. That's strange.
      # Instead, deserialize them now. Also, clear `serialized_arguments` to prevent ActiveJob from overwriting changes
      # to arguments when serializing later.
      job.arguments = ActiveJob::Arguments.deserialize(job_data['arguments'])
      job.serialized_arguments = nil

      job.successfully_enqueued = !job.enqueued_at.nil?

      job
    end

    # Enqueues a job, optionally at the specified time.
    #
    # @param job [ActiveJob::Base] the job to enqueue
    # @param timestamp [Numeric, NilClass] optional number of seconds since Unix epoch at which to execute the job
    # @return [ActiveJob::Base] the enqueued job
    def enqueue(job, timestamp = nil)
      job.scheduled_at = timestamp ? Time.at(timestamp).utc : nil

      job.enqueued_at = Time.now.utc.to_time
      if (record = Arj.record_class.find_by(job_id: job.job_id))
        record.update!(record_attributes(job))
      else
        record = Arj.record_class.create!(record_attributes(job))
      end
      Arj.from(record, job)

      job
    end

    protected

    # Returns serialized job data for the specified database record.
    #
    # @param record [ActiveRecord::Base]
    # @return [Hash]
    def job_data(record)
      record.attributes.fetch_values(*REQUIRED_RECORD_ATTRIBUTES)
      job_data = record.attributes
      job_data['arguments'] = JSON.parse(job_data['arguments'])
      job_data['exception_executions'] = JSON.parse(job_data['exception_executions'])
      job_data['enqueued_at'] = job_data['enqueued_at'].iso8601 if job_data['enqueued_at']
      job_data['scheduled_at'] = job_data['scheduled_at']&.iso8601 if job_data['scheduled_at']
      job_data
    end

    # Returns database record attributes for the specified job.
    #
    # @param job [ActiveJob::Base]
    # @return [Hash]
    def record_attributes(job)
      serialized = job.serialize
      serialized.fetch_values(*REQUIRED_JOB_ATTRIBUTES)
      serialized.delete('provider_job_id')
      serialized['arguments'] = serialized['arguments'].to_json
      serialized['exception_executions'] = serialized['exception_executions'].to_json

      # ActiveJob::Base#serialize always returns Time.now.utc.iso8601(9) for enqueued_at.
      serialized['enqueued_at'] = job.enqueued_at&.utc

      # ActiveJob::Base#serialize always returns I18n.locale.to_s for locale.
      serialized['locale'] = job.locale || serialized['locale']

      serialized.symbolize_keys
    end
  end
end
