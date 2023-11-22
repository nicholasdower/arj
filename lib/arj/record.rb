# frozen_string_literal: true

module Arj
  # A module which, when included, adds {Arj::Record::ClassMethods class methods} used to query jobs.
  #
  # Example usage:
  #   class Job < ActiveRecord::Base
  #     include Arj::Record
  #   end
  #
  #   Job.queue('some queue') # Returns record objects
  #   Arj.queue('some queue') # Returns job objects
  module Record
    # Class methods which are automatically added when {Record} is included in a class.
    module ClassMethods
      # Returns a {Relation} scope for jobs which have been executed one or more times.
      #
      # @return [Arj::Relation]
      def failing
        where('executions > ?', 0)
      end

      # Returns a {Relation} scope for jobs in the specified queue(s).
      #
      # @param queues [Array<String]
      # @return [Arj::Relation]
      def queue(*queues)
        where(queue_name: queues)
      end

      # Returns a {Relation} scope for jobs with a +scheduled_at+ that is either +null+ or in the past.
      #
      # @return [Arj::Relation]
      def executable
        where('scheduled_at is null or scheduled_at <= ?', Time.now.utc)
      end

      # Returns a {Relation} scope for {executable} jobs in order.
      #
      # Jobs are ordered by:
      # - +priority+ (+null+ last)
      # - +scheduled_at+ (+null+ last)
      # - +enqueued_at+
      #
      # @return [Arj::Relation]
      def todo
        executable.order(
          Arel.sql(
            <<~SQL.squish
              CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority,
              CASE WHEN scheduled_at IS NULL THEN 1 ELSE 0 END, scheduled_at,
              enqueued_at
            SQL
          )
        )
      end

      # Overridden so that job records will be ordered by +enqueued_at+ rather than +job_id+ (the default).
      #
      # @return [String]
      def implicit_order_column
        'enqueued_at'
      end
    end

    # Returns the corresponding job for this record.
    #
    # @return [ActiveJob::Base]
    def to_arj
      Arj.from(self)
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
