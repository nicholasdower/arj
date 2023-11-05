# frozen_string_literal: true

require 'active_record'
require_relative 'arj_adapter'
require_relative 'arj/persistence'
require_relative 'arj/query_methods'
require_relative 'arj/relation'
require_relative 'arj/version'
require_relative 'arj/worker'

# Arj. An ActiveJob queuing backend which uses ActiveRecord.
#
# The Arj module provides:
# - Global Arj settings {record_class} and {base_classes}.
# - Job query methods. See {Arj::QueryMethods}.
# - Job persistence methods similar to {Arj::Persistence}.
module Arj
  @record_class = 'Job'
  @base_classes = %w[ApplicationJob]

  include QueryMethods

  class << self
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

    # List of names of job classes which should be considered base classes for the purposes of querying. Defaults to
    # +"ApplicationJob"+.
    #
    # For instance, given the following classes:
    #
    #   class ApplicationJob < ActiveJob::Base
    #     include Arj::QueryMethods
    #   end
    #
    #   class BaseJob < ApplicationJob
    #     Arj.base_classes << name
    #   end
    #
    #   class ChildJob < BaseJob; end
    #
    # Querying via these classes would produce the following results:
    #
    #   ApplicationJob.last # Returns the last job, regardless of type
    #   BaseJob.last        # Returns the last job, regardless of type
    #   ChildJob.last       # Returns the last job of type ChildJob
    #
    # @return [Array<String>]
    attr_reader :base_classes

    # @return [Boolean] +true+ if the specified job has a corresponding record in the database
    def exists?(job)
      job.provider_job_id.nil? ? false : Arj.record_class.exists?(job.provider_job_id)
    end

    # Reloads the attributes of the specified job from the database.
    #
    # @return [ActiveJob::Base] the specified job, updated
    def reload(job)
      raise 'record not set' if job.provider_job_id.nil?

      record = Arj.record_class.find(job.provider_job_id)
      Persistence.from_record(record, job)
      job
    rescue ActiveRecord::RecordNotFound
      job.successfully_enqueued = false
      raise
    end

    # Saves the database record associated with the specified job. Raises if the record is invalid.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base; end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   job.queue_name = 'other queue'
    #   Arj.save!(job)
    #
    # @return [Boolean] +true+
    def save!(job)
      raise 'record not set' if job.provider_job_id.nil?

      record = Arj.record_class.find(job.provider_job_id)
      record.update!(Persistence.record_attributes(job)).tap { Persistence.from_record(record, job) }
    end

    # Updates the database record associated with the specified job. Raises if the record is invalid.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base; end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   Arj.update!(job, queue_name: 'other queue')
    #
    # @return [Boolean] +true+
    def update!(job, attributes)
      raise "invalid attributes: #{attributes}" unless attributes.is_a?(Hash)
      raise 'record not set' if job.provider_job_id.nil?

      attributes.each { |k, v| job.send("#{k}=".to_sym, v) }
      record = Arj.record_class.find(job.provider_job_id)
      record.update!(Persistence.record_attributes(job))
    end

    # Destroys the database record associated with the specified job.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base; end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   Arj.destroy!(job)
    #
    # @return [ActiveJob::Base] the specified job
    def destroy!(job)
      raise 'record not set' if job.provider_job_id.nil?

      record = Arj.record_class.find(job.provider_job_id)
      record.destroy!
      job.successfully_enqueued = false
      job
    end

    # @return [Boolean] +true+ if the specified job has been deleted from the database
    def destroyed?(job)
      raise 'record not set' if job.provider_job_id.nil?

      exists?(job)
    end
  end
end
