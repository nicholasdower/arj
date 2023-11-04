# frozen_string_literal: true

require 'active_record'
require_relative 'arj_adapter'
require_relative 'arj/persistence'
require_relative 'arj/query_methods'
require_relative 'arj/relation'
require_relative 'arj/version'
require_relative 'arj/worker'

# Provides:
#   - Global Arj settings `record_class` and `base_classes`.
#   - Job query and persistence methods.
module Arj
  @record_class = 'Job'
  @base_classes = %w[ApplicationJob]

  class << self
    include QueryMethods::ClassMethods

    # Sets the ActiveRecord job class used to interact with jobs in the database.
    #
    # Defaults to `Job`.
    def record_class=(clazz)
      raise "invalid class: #{clazz || 'nil'}" unless clazz.is_a?(Class) || clazz.is_a?(String)

      @record_class = clazz
    end

    # Returns the ActiveRecord job class.
    def record_class
      @record_class = @record_class.constantize if @record_class.is_a?(String)
      @record_class
    end

    # Sets the list of `ActiveJob::Base` subclasses which should be considered base classes for the purposes of
    # querying. For instance, if `BaseJob` is configured as a base class and `ChildJob` isn't, `BaseJob.last` would
    # return the last job, regardless of type, whereas `ChildJob.last` would return the last job of type `ChildJob`.
    #
    # Defaults to `[ActiveJob]`.
    def base_classes=(classes)
      raise "base classes not enumerable: #{classes}" unless classes <= Enumerable

      @base_classes = classes.map do |clazz|
        if clazz.is_a?(String)
          clazz
        elsif clazz.is_a?(Class)
          clazz.name
        else
          raise "invalid base class: #{clazz}"
        end
      end.freeze
    end

    # Returns the list of `ActiveJob::Base` subclasses which should be considered base classes for the purposes of
    # querying. For instance, if `BaseJob` is configured as a base class and `ChildJob` isn't, `BaseJob.last` would
    # return the last job, regardless of type, whereas `ChildJob.last` would return the last job of type `ChildJob`.
    def base_classes
      @base_classes
    end

    # Returns the next performable job in the specified queue (or any queue if none is specified) and with fewer than
    # the specified number of maximum executions (or any number of executions if none is specified).
    #
    # A job is considered performable if `scheduled_at` is `nil` or in the past.
    def next(queue_name: nil, max_executions: nil)
      relation = Arj.where('scheduled_at is null or scheduled_at < ?', Time.zone.now)
      relation = relation.where(queue_name:) if queue_name
      relation = relation.where('executions < ?', max_executions) if max_executions
      relation.order(priority: :asc, scheduled_at: :asc).first
    end

    def exists?(job)
      job.provider_job_id.nil? ? false : Arj.record_class.exists?(job.provider_job_id)
    end

    def destroyed?(job)
      raise 'record not set' if job.provider_job_id.nil?

      exists?(job)
    end

    def reload(job)
      raise 'record not set' if job.provider_job_id.nil?

      record = Arj.record_class.find(job.provider_job_id)
      Persistence.from_record(record, job)
      job
    rescue ActiveRecord::RecordNotFound
      job.successfully_enqueued = false
      raise
    end

    def save!(job)
      raise 'record not set' if job.provider_job_id.nil?

      record = Arj.record_class.find(job.provider_job_id)
      record.update!(Persistence.record_attributes(job))
      Persistence.from_record(record, job)
      job
    end

    def update!(job, attributes)
      raise "invalid attributes: #{attributes}" unless attributes.is_a?(Hash)
      raise 'record not set' if job.provider_job_id.nil?

      attributes.each { |k, v| job.send("#{k}=".to_sym, v) }
      record = Arj.record_class.find(job.provider_job_id)
      record.update!(Persistence.record_attributes(job))

      job
    end

    def destroy!(job)
      raise 'record not set' if job.provider_job_id.nil?

      record = Arj.record_class.find(job.provider_job_id)
      record.destroy!
      job.successfully_enqueued = false
      job
    end
  end
end
