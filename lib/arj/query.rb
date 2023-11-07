# frozen_string_literal: true

require_relative '../arj'
require_relative 'query_documentation'
require_relative 'relation'

module Arj
  # ActiveRecord-style query methods (+where+, +first+, +last+, etc.), but for jobs.
  #
  # Example usage:
  #   class SampleJob < ActiveJob::Base
  #     include Arj::Query
  #   end
  #
  #   SampleJob.set(queue_name: 'some queue').perform_later('some arg')
  #   job = job.where(queue_name: 'some queue').first
  #   job.perform_now
  #
  # This module is also included in the {Arj} module.
  #
  # Example usage:
  #   class SampleJob < ActiveJob::Base; end
  #
  #   SampleJob.set(queue_name: 'some queue').perform_later('some arg')
  #   job = Arj.where(queue_name: 'some queue').first
  #   job.perform_now
  #
  # Note that all query methods delegate to {Query::ClassMethods.all}. Override {Query::ClassMethods.all}
  # to customize. For instance, to create a job group:
  #   class FooBarJob < ActiveJob::Base; end
  #   class FooBazJob < ActiveJob::Base; end
  #
  #   module FooJobs
  #     include Arj::Query
  #
  #     def self.all
  #       Arj.where(job_class: [FooBarJob, FooBazJob].map(&:name))
  #     end
  #   end
  #
  #   FooBarJob.perform_later
  #   FooBazJob.perform_later
  #   FooJobs.available.first # Returns the first available job of type FooBarJob or FooBazJob.
  #
  # See {https://www.rubydoc.info/github/rails/rails/ActiveRecord/QueryMethods ActiveRecord::QueryMethods},
  # {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Result ActiveRecord::Result} and
  # {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Result ActiveRecord::Relation}
  module Query
    # Class methods which are automatically added when {Query} is included in a class.
    #
    # See {Arj::Query} and {Arj::QueryDocumentation}
    module ClassMethods
      include Arj::QueryDocumentation

      delegate(*ActiveRecord::Querying::QUERYING_METHODS, to: :all)

      # Returns a {Relation} scope object for all jobs.
      #
      # @return [Relation]
      def all
        raise 'no record class configured' unless Arj.record_class

        if self == Arj
          Relation.new(Arj.record_class.all)
        else
          Relation.new(Arj.record_class.where(job_class: name).all)
        end
      end

      # Returns a {Relation} scope for available jobs.
      #
      # Jobs are considered available if +scheduled_at+ is null or in the past. Jobs are ordered by +priority+
      # (ascending, nulls last) followed by +created_at+ (ascending).
      #
      # The following optional criteria may be specified:
      # - One or more queues
      # - The maximum number of executions (exclusive)
      #
      # @param queue_name [String, Array]
      # @param max_executions [Numeric]
      # @return [ActiveJob::Base]
      def available(queue_name: nil, max_executions: nil)
        relation = where('scheduled_at is null or scheduled_at < ?', Time.zone.now)
        relation = relation.where(queue_name:) if queue_name
        relation = relation.where('executions < ?', max_executions) if max_executions
        relation.order(Arel.sql('CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority, created_at'))
      end
    end

    # Adds {ClassMethods} when this module is included.
    #
    # @param clazz [Class]
    # @return [Class]
    def self.included(clazz)
      clazz.extend ClassMethods
    end
  end
end
