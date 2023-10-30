# frozen_string_literal: true

module Arj
  # Base Arj job class
  class Job < ActiveJob::Base
    attr_reader :arj_record

    class << self
      attr_writer :arj_record_class
    end

    def self.arj_record_class
      @arj_record_class || (superclass.arj_record_class if self < Job)
    end

    def initialize(...)
      super
      @arj_enqueued = false
      @arj_record = nil
    end

    def arj_enqueue!(timestamp = nil)
      self.scheduled_at = timestamp ? Time.zone.at(timestamp) : nil
      @arj_record ? arj_save! : arj_create_record!
      @arj_enqueued = true
      self
    end

    def arj_enqueued?
      @arj_enqueued
    end

    def arj_save!
      @arj_record.update!(serialize)
      self
    end

    def arj_destroy!
      @arj_record.destroy!
      self
    end

    def perform_now
      @arj_enqueued = false
      super.tap { arj_destroy! unless @arj_enqueued }
    end

    def retry_job(options = {})
      super.tap { @arj_enqueued = true }
    end

    def serialize
      serialized = super
      {
        job_class: serialized['job_class'],
        job_id: serialized['job_id'],
        queue_name: serialized['queue_name'],
        priority: serialized['priority'],
        arguments: ActiveJob::Arguments.serialize(arguments).to_yaml,
        executions: serialized['executions'],
        exception_executions: serialized['exception_executions'].to_json,
        locale: serialized['locale'],
        timezone: serialized['timezone'],
        enqueued_at: Time.zone.iso8601(serialized['enqueued_at']),
        scheduled_at: serialized['scheduled_at'] ? Time.zone.iso8601(serialized['scheduled_at']) : nil
      }
    end

    def arj_deserialize(record)
      raise "record already set: #{@arj_record.id}" if @arj_record

      @arj_record = record
      @arj_enqueued = true
      self.provider_job_id = @arj_record.id
      self.successfully_enqueued = true
      self.job_id = @arj_record.job_id
      self.provider_job_id = @arj_record.id
      self.queue_name = @arj_record.queue_name
      self.priority = @arj_record.priority
      self.serialized_arguments = YAML.load(@arj_record.arguments)
      self.executions = @arj_record.executions
      self.exception_executions = @arj_record.exception_executions ? JSON.parse(@arj_record.exception_executions) : nil
      self.locale = @arj_record.locale
      self.timezone = @arj_record.timezone
      self.enqueued_at = @arj_record.enqueued_at
      self.scheduled_at = @arj_record.scheduled_at

      self
    end

    private

    def arj_create_record!
      raise "record already created: #{@arj_record.id}" if @arj_record

      @arj_record = Arj.model_class.create!(serialize)
    end
  end
end
