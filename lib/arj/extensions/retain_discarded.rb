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
    #     include Arj::Job
    #     include Arj::Extensions::RetainDiscarded
    #   end
    #
    #   class Job < ActiveRecord::Base
    #     include Arj::Record
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
      # Includes either {Arj::Extensions::RetainDiscarded::Job} or {Arj::Extensions::RetainDiscarded::Record} depending
      # on class type.
      #
      # @param clazz [Class]
      # @return [Class]
      def self.included(clazz)
        if clazz.ancestors.map(&:name).include?('ActiveRecord::Base')
          clazz.include(Arj::Extensions::RetainDiscarded::Record)
        elsif clazz <= ActiveJob::Base
          clazz.include(Arj::Extensions::RetainDiscarded::Job)
        else
          raise "expected ActiveRecord::Base or ActiveJob::Job, found #{clazz.name}"
        end
      end

      # Adds a +discarded_at+ column to the jobs table.
      #
      # @param migration [Class<ActiveRecord::Migration>]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_up(migration, table_name: :jobs)
        migration.add_column table_name, :discarded_at, :datetime
        migration.change_column table_name, :enqueued_at, :datetime, null: true
      end

      # Removes the +discarded_at+ column from the jobs table.
      #
      # @param migration [Class<ActiveRecord::Migration>]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_down(migration, table_name: :jobs)
        migration.remove_column table_name, :discarded_at
        migration.change_column table_name, :enqueued_at, :datetime, null: false
      end

      # The module included in +ActiveJob::Base+ classes to provide job retention functionality.
      module Job
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
              Arj.save_job!(job)
            else
              Arj.record_class.find(job.job_id)&.destroy!
            end
            nil
          end
        end

        # Extends the specified class with {Arj::Extensions::RetainDiscarded::Job::ClassMethods}.
        #
        # @param clazz [Class]
        # @return [Class]
        def self.included(clazz)
          clazz.extend(Arj::Extensions::RetainDiscarded::Job::ClassMethods)
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
      end

      # The module included in +ActiveRecord::Base+ classes to provide job querying functionality.
      module Record
        # Class methods which are automatically added when {Record} is included in a class.
        module ClassMethods
          # Returns a {Relation} scope for jobs where +discarded_at+ is not +null+.
          #
          # See: [Arj::Extensions::RetainDiscarded]
          #
          # @return [Arj::Relation]
          def discarded
            where('discarded_at is not null')
          end

          # Returns a {Relation} scope for jobs with a +scheduled_at+ that is either +null+ or in the past.
          #
          # @return [Arj::Relation]
          def executable
            super.where('discarded_at is null')
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
  end
end
