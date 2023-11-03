# frozen_string_literal: true

require 'active_job'
require 'active_job/arguments'
require 'active_record'
require 'json'
require_relative '../arj'

module Arj
  module Persistence
    REQUIRED_JOB_ATTRIBUTES = %w[
      job_class job_id provider_job_id queue_name
      priority arguments executions exception_executions
      locale timezone enqueued_at scheduled_at
    ].freeze
    REQUIRED_RECORD_ATTRIBUTES = %w[
      job_class job_id queue_name priority arguments executions
      exception_executions locale timezone enqueued_at scheduled_at
    ].freeze

    class << self
      def enqueue_record(job, timestamp = nil)
        job.scheduled_at = timestamp ? Time.zone.at(timestamp) : nil

        if job.provider_job_id
          record = Arj.record_class.find(job.provider_job_id)
          record.update!(Persistence.serialize(job))
        else
          record = Arj.record_class.create!(Persistence.serialize(job))
          enhance(job)
        end
        Persistence.from_record(record, job)

        job
      end

      def enhance(job)
        job.singleton_class.class_eval do
          def perform_now
            self.successfully_enqueued = false
            super
          ensure
            Arj.record_class.find(provider_job_id).destroy! unless successfully_enqueued?
          end
        end

        job
      end

      def from_record(record, job = nil)
        raise "expected #{Arj.record_class}, found #{record.class}" unless record.is_a?(Arj.record_class)

        job ||= Object.const_get(record.job_class).new
        raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

        if job.provider_job_id && job.provider_job_id != record.id
          raise "record already set on #{job.class}: #{job.provider_job_id}"
        end

        job.successfully_enqueued = true
        record.attributes.fetch_values(*REQUIRED_RECORD_ATTRIBUTES)
        job_data = record.attributes.slice(*REQUIRED_RECORD_ATTRIBUTES)
        job_data['provider_job_id'] = record.id
        serialized_arguments = JSON.parse(job_data['arguments'])
        job_data['arguments'] = serialized_arguments
        job_data['exception_executions'] = JSON.parse(job_data['exception_executions'])
        job_data['enqueued_at'] = record.enqueued_at.iso8601
        job_data['scheduled_at'] = record.scheduled_at&.iso8601 if job_data['scheduled_at']

        job.deserialize(job_data)

        # ActiveJob deserializes arguments on demand.
        job.arguments = ActiveJob::Arguments.deserialize(serialized_arguments)

        job
      end

      def serialize(job)
        serialized = job.serialize
        serialized.fetch_values(*REQUIRED_JOB_ATTRIBUTES)
        serialized.slice!(*REQUIRED_JOB_ATTRIBUTES)
        serialized.delete('provider_job_id')
        serialized['arguments'] = serialized['arguments'].to_json
        serialized['exception_executions'] = serialized['exception_executions'].to_json

        serialized
      end
    end

    def reload
      record = Arj.record_class.find(provider_job_id)
      Persistence.from_record(record, self)
      self
    rescue ActiveRecord::RecordNotFound
      self.successfully_enqueued = false
      raise
    end

    def save!
      record = Arj.record_class.find(provider_job_id)
      record.update!(Persistence.serialize(self))
      Persistence.from_record(record, self)
      self
    end

    def update!(attributes)
      raise "invalid attributes: #{attributes}" unless attributes.is_a?(Hash)

      attributes.each { |k, v| send("#{k}=".to_sym, v) }
      record = Arj.record_class.find(provider_job_id)
      record.update!(Persistence.serialize(self))

      self
    end

    def destroy!
      record = Arj.record_class.find(provider_job_id)
      record.destroy!
      self.successfully_enqueued = false
      self
    end
  end
end
