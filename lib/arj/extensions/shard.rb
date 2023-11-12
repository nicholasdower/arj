# frozen_string_literal: true

module Arj
  module Extensions
    # Adds a +shard+ attribute to a job class.
    #
    # Example usage:
    #   class AddShardToJobs < ActiveRecord::Migration[7.1]
    #     def change
    #       add_column :jobs, :shard, :string
    #     end
    #   end
    #
    #   class SampleJob < ActiveJob::Base
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
    end
  end
end
