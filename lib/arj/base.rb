# frozen_string_literal: true

require 'active_job'
require 'yaml'

module Arj
  # Base Arj job class
  class Base < ActiveJob::Base
    REQUIRED_JOB_ATTRIBUTES = %w[
      job_class job_id provider_job_id queue_name
      priority arguments executions exception_executions
      locale timezone enqueued_at scheduled_at
    ].freeze
    REQUIRED_RECORD_ATTRIBUTES = %w[
      job_class job_id queue_name priority arguments executions
      exception_executions locale timezone enqueued_at scheduled_at
    ].freeze

    attr_reader :record

    class << self
      delegate :all, :where, :count, :first, :last, :sole, :take, :pluck, :destroy_all, :destroy, to: :record_relation

      def record_class=(clazz)
        raise 'use Arj::Base to set record class' unless self == Arj::Base
        raise "invalid record class: #{clazz}" unless clazz.is_a?(Class) || clazz.is_a?(String)

        @record_class = clazz
      end

      def record_class
        raise 'use Arj::Base to get record class' unless self == Arj::Base

        @record_class ||= 'Job'.constantize
      end

      def record_relation
        raise 'no record class configured' unless Arj::Base.record_class

        if self == Base || name == 'ApplicationJob'
          Relation.new(Arj::Base.record_class)
        else
          Relation.new(Arj::Base.record_class.where(job_class: name))
        end
      end

      def from_record(record)
        raise "expected #{Arj::Base.record_class}, found #{record.class}" unless record.is_a?(Arj::Base.record_class)

        job = Object.const_get(record.job_class).new
        raise "expected Arj::Base, found #{job.class}" unless job.is_a?(Arj::Base)

        job.deserialize_record(record)
      end
    end

    def initialize(...)
      super
      @record_enqueued = false
      @record = nil
    end

    def enqueue_record!(timestamp = nil)
      self.scheduled_at = timestamp ? Time.zone.at(timestamp) : nil
      if @record
        save_record!
      else
        deserialize_record(Arj::Base.record_class.create!(serialize))
      end
      @record_enqueued = true
      self
    end

    def record_enqueued?
      @record_enqueued
    end

    def save_record!
      @record.update!(serialize)
      self
    end

    def update_record!(...)
      @record.update!(...)
      deserialize_record
      self
    end

    def destroy_record!
      @record.destroy!
      self
    end

    def perform_now
      @record_enqueued = false
      super.tap { destroy_record! unless @record_enqueued }
    end

    def retry_job(options = {})
      super.tap { @record_enqueued = true }
    end

    def serialize
      super.fetch_values(*REQUIRED_JOB_ATTRIBUTES)
      serialized = super.slice(*REQUIRED_JOB_ATTRIBUTES).tap { |h| h.delete('provider_job_id') }
      serialized['arguments'] = serialized['arguments'].to_json
      serialized['exception_executions'] = serialized['exception_executions'].to_json

      serialized
    end

    def deserialize_record(record = @record)
      @record = record
      @record_enqueued = true

      @record.attributes.fetch_values(*REQUIRED_RECORD_ATTRIBUTES)
      job_data = @record.attributes.slice(*REQUIRED_RECORD_ATTRIBUTES)
      job_data['provider_job_id'] = @record.id
      job_data['arguments'] = JSON.parse(job_data['arguments'])
      job_data['exception_executions'] = JSON.parse(job_data['exception_executions'])
      job_data['enqueued_at'] = @record.enqueued_at.iso8601
      job_data['scheduled_at'] = @record.scheduled_at&.iso8601 if job_data['scheduled_at']

      deserialize(job_data)

      deserialize_arguments_if_needed

      self
    end
  end
end
