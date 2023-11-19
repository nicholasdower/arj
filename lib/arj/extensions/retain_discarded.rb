# frozen_string_literal: true

module Arj
  module Extensions
    # Provides the ability to retain discarded jobs.
    #
    # Example usage:
    #   class AddRetainDiscardedToJobs < ActiveRecord::Migration[7.1]
    #     def self.up
    #       Arj::Extensions::RetainDiscarded.migrate_up(self)
    #     end
    #
    #     def self.down
    #       Arj::Extensions::RetainDiscarded.migrate_down(self)
    #     end
    #   end
    #
    #   class SampleJob < ActiveJob::Base
    #     include Arj
    #     include Arj::Extensions::RetainDiscarded
    #   end
    #
    #   job = SampleJob.perform_later
    #   job.perform_now rescue nil
    #
    #   job.discarded?
    #   job.discarded_at
    #   Arj.discarded
    module RetainDiscarded
      # An optional String representing a shard.
      #
      # @return [Time]
      attr_accessor :discarded_at

      # Class methods added to jobs which include {Arj::Extensions::RetainDiscarded}.
      module ClassMethods
        # Enables retention of discarded jobs (the default behavior).
        #
        # @return [NilClass]
        def retain_discarded
          @retain_discarded = true
          nil
        end

        # Disables retention of discarded jobs.
        #
        # @return [NilClass]
        def destroy_discarded
          @retain_discarded = false
          nil
        end

        # Returns +true+ if discarded jobs will be retained in the database.
        #
        # @return [Boolean]
        def retain_discarded?
          @retain_discarded.nil? ? true : @retain_discarded
        end

        # Arj Callback invoked when a job is to be discarded.
        #
        # @return [NilClass]
        def on_discard(job)
          job.discarded_at = Time.now.utc
          if retain_discarded?
            Arj.save!(job)
          else
            Arj.record_class.find(job.job_id)&.destroy!
          end
          nil
        end
      end

      # Extends the specified class with {Arj::Extensions::RetainDiscarded::ClassMethods}.
      #
      # @param clazz [Class]
      # @return [Class]
      def self.included(clazz)
        clazz.extend(Arj::Extensions::RetainDiscarded::ClassMethods)
        clazz.before_enqueue do |job|
          job.discarded_at = nil
        end
      end

      # Returns +true+ if this job has been discarded.
      #
      # @return [Boolean]
      def discarded?
        !@discarded_at.nil?
      end

      # Overridden to add support for serializing the +shard+ attribute.
      #
      # @return [Hash]
      def serialize
        unless Arj.record_class.attribute_names.include?('discarded_at')
          raise "#{Arj.record_class.name} class missing discarded_at attribute"
        end

        super.merge('discarded_at' => @discarded_at)
      end

      # Overridden to add support for deserializing the +discarded_at+ attribute.
      #
      # @param job_data [Hash]
      def deserialize(job_data)
        raise "#{Arj.record_class.name} data missing discarded_at attribute" unless job_data.key?('discarded_at')

        super.tap { @discarded_at = job_data['discarded_at']&.utc }
      end

      # Adds a +discarded_at+ column to the jobs table.
      #
      # @param migration [ActiveRecord::Migration]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_up(migration, table_name: :jobs)
        migration.add_column table_name, :discarded_at, :datetime
        migration.change_column table_name, :enqueued_at, :datetime
      end

      # Removes the +discarded_at+ column from the jobs table.
      #
      # @param migration [ActiveRecord::Migration]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_down(migration, table_name: :jobs)
        migration.remove_column table_name, :discarded_at
        migration.change_column table_name, :enqueued_at, :datetime, null: false
      end
    end
  end
end
