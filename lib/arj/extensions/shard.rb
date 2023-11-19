# frozen_string_literal: true

module Arj
  module Extensions
    # Adds a +shard+ attribute to a job class.
    #
    # Example usage:
    #   class AddShardToJobs < ActiveRecord::Migration[7.1]
    #     def self.up
    #       Arj::Extensions::Shard.migrate_up(self)
    #     end
    #
    #     def self.down
    #       Arj::Extensions::Shard.migrate_down(self)
    #     end
    #   end
    #
    #   class SampleJob < ActiveJob::Base
    #     include Arj
    #     include Arj::Extensions::Shard
    #   end
    #
    #   SampleJob.set(shard: 'some shard').perform_later
    module Shard
      # An optional String representing a shard.
      #
      # @return [String]
      attr_accessor :shard

      # Overridden to add support for setting the +shard+ attribute.
      #
      # @param options [Hash]
      # @return [ActiveJob::ConfiguredJob]
      def set(options = {})
        super.tap { @shard = options[:shard] if options.key?(:shard) }
      end

      # Overridden to add support for serializing the +shard+ attribute.
      #
      # @return [Hash]
      def serialize
        unless Arj.record_class.attribute_names.include?('shard')
          raise "#{Arj.record_class.name} class missing shard attribute"
        end

        super.merge('shard' => @shard)
      end

      # Overridden to add support for deserializing the +shard+ attribute.
      #
      # @param job_data [Hash]
      def deserialize(job_data)
        raise "#{Arj.record_class.name} data missing shard attribute" unless job_data.key?('shard')

        super.tap { @shard = job_data['shard'] }
      end

      # Adds a +shard+ column to the jobs table.
      #
      # @param migration [ActiveRecord::Migration]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_up(migration, table_name: :jobs)
        migration.add_column table_name, :shard, :string
      end

      # Removes the +shard+ column from the jobs table.
      #
      # @param migration [ActiveRecord::Migration]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_down(migration, table_name: :jobs)
        migration.remove_column table_name, :shard
      end
    end
  end
end
