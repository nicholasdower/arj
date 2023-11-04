# frozen_string_literal: true

require_relative '../arj'
require_relative 'relation'

module Arj
  # ActiveRecord-style query methods (+where+, +first+, +last+, etc.), but for jobs.
  #
  # Example usage
  #   class SampleJob < ActiveJob::Base
  #     include Arj::QueryMethods
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
  module QueryMethods
    module ClassMethods
      delegate(*ActiveRecord::Querying::QUERYING_METHODS, to: :all)

      # Returns an {Arj::Relation} wrapping an ActiveRecord::Relation scope object.
      def all
        raise 'no record class configured' unless Arj.record_class

        if self == Arj || Arj.base_classes.include?(name)
          Relation.new(Arj.record_class.all)
        else
          Relation.new(Arj.record_class.where(job_class: name).all)
        end
      end

      # Returns the first available job.
      #
      # Jobs are ordered by:
      # - +priority+ ascending, nulls last
      # - +scheduled_at+ ascending, nulls last
      #
      # The following criteria may optionally be specified:
      # - One or more queues
      # - The maximum number of executions (exclusive)
      #
      # @return [ActiveJob::Base]
      def next(queue_name: nil, max_executions: nil)
        Arj.next(job_class: name, queue_name:, max_executions:)
      end
    end

    def self.included(clazz)
      clazz.extend ClassMethods
    end
  end
end
