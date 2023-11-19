# frozen_string_literal: true

module Arj
  module Extensions
    # Adds support for populating the +provider_job_id+ job attribute from an +id+ column.
    #
    # Example usage:
    #   class AddIdToJobs < ActiveRecord::Migration[7.1]
    #     def self.up
    #       Arj::Extensions::Id.migrate_up(self)
    #     end
    #
    #     def self.down
    #       Arj::Extensions::Id.migrate_down(self)
    #     end
    #   end
    #
    #   class SampleJob < ActiveJob::Base
    #     include Arj
    #     include Arj::Extensions::Id
    #   end
    #
    #   job = SampleJob.perform_later
    #   job.provider_job_id
    module Id
      # Overridden to add support for deserializing the +provider_job_id+ attribute.
      #
      # @param job_data [Hash]
      def deserialize(job_data)
        raise "#{Arj.record_class.name} data missing id attribute" unless job_data.key?('id')

        super.tap { self.provider_job_id = job_data['id'] }
      end

      # Adds an +id+ column to the jobs table.
      #
      # @param migration [ActiveRecord::Migration]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_up(migration, table_name: :jobs)
        migration.remove_column table_name, :job_id
        migration.add_column table_name, :job_id, :string, null: false
        migration.add_column table_name, :id, :integer, null: false, primary_key: true
        migration.add_index table_name, :job_id, unique: true
        nil
      end

      # Removes the +id+ column from the jobs table.
      #
      # @param migration [ActiveRecord::Migration]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_down(migration, table_name: :jobs)
        migration.remove_column table_name, :id
        migration.remove_column table_name, :job_id
        migration.add_column table_name, :job_id, :string, null: false, primary_key: true
        migration.add_index table_name, :job_id, unique: true
      end
    end
  end
end
