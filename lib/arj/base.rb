# frozen_string_literal: true

require 'active_job'
require 'yaml'

module Arj
  # Base Arj job class
  class Base < ActiveJob::Base
    RECORD_FIELDS = %w[
      job_class job_id job_provider_id queue_name
      priority arguments executions exception_executions
      locale timezone enqueued_at scheduled_at
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

      def next_job(queue_name: nil, max_executions: nil)
        relation = where('scheduled_at is null or scheduled_at < ?', Time.zone.now)
        relation = relation.where(queue_name:) if queue_name
        relation = relation.where('executions < ?', max_executions) if max_executions
        relation.order(priority: :asc, scheduled_at: :asc).first
      end
    end

    def initialize(...)
      super
      @record_enqueued = false
      @record = nil
    end

    def arj_enqueue!(timestamp = nil)
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
      serialized = super.slice(*RECORD_FIELDS)
      serialized['arguments'] = serialized['arguments'].to_json
      serialized['exception_executions'] = serialized['exception_executions'].to_json

      serialized
    end

    def deserialize_record(record)
      raise "record already set: #{@record.id}" if @record

      @record = record
      @record_enqueued = true

      job_data = @record.attributes.slice(*RECORD_FIELDS)
      job_data['arguments'] = JSON.parse(job_data['arguments'])
      job_data['exception_executions'] = JSON.parse(job_data['exception_executions'])
      job_data['provider_job_id'] = @record.id
      job_data['enqueued_at'] = @record.enqueued_at.iso8601
      job_data['scheduled_at'] = @record.scheduled_at&.iso8601

      deserialize(job_data)

      # TODO: this method is private
      deserialize_arguments_if_needed

      self
    end
  end
end
