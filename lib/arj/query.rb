# frozen_string_literal: true

require_relative '../arj'
require_relative 'documentation/active_record_relation'
require_relative 'documentation/arj_relation'
require_relative 'relation'

module Arj
  # A module which, when included, adds class methods used to query jobs.
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
  # This module is also included in the {Arj} module:
  #
  #   class SampleJob < ActiveJob::Base; end
  #
  #   SampleJob.set(queue_name: 'some queue').perform_later('some arg')
  #   job = Arj.where(queue_name: 'some queue').first
  #   job.perform_now
  #
  # Note that all query methods delegate to {Query::ClassMethods.all}. This method can be overridden to create a
  # customized query interface. For instance, to create a job group:
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
  # See {Arj::Relation}.
  module Query
    # Class methods which are automatically added when {Query} is included in a class.
    module ClassMethods
      include Arj::Documentation::ActiveRecordRelation
      delegate(*ActiveRecord::Querying::QUERYING_METHODS, to: :all)

      include Arj::Documentation::ArjRelation
      delegate(*Arj::Relation::QUERY_METHODS, to: :all)

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
