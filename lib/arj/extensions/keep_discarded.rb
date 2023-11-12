# frozen_string_literal: true

module Arj
  module Extensions
    # Provides the ability to retain discarded jobs.
    #
    # Example usage:
    #   class AddFailedAtToJobs < ActiveRecord::Migration[7.1]
    #     def change
    #       add_column :jobs, :discarded_at, :datetime
    #     end
    #   end
    #
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Extensions::KeepDiscarded
    #
    #     retry_on Exception
    #   end
    #
    #   SampleJob.perform_later
    module KeepDiscarded
      # An optional String representing a shard.
      #
      # @return [Time]
      attr_accessor :discarded_at

      # Class methods added to jobs which include {Arj::Extensions::FailedAt}.
      module ClassMethods
        # Enables retention of discarded jobs (the default behavior).
        #
        # @return [NilClass]
        def keep_discarded
          @keep_discarded = true
          nil
        end

        # Disables retention of discarded jobs.
        #
        # @return [NilClass]
        def destroy_discarded
          @keep_discarded = false
          nil
        end

        # Returns +true+ if discarded jobs will be retained in the database.
        #
        # @return [Boolean]
        def keep_discarded?
          @keep_discarded || true
        end

        # Arj Callback invoked when a job is to be discarded.
        def on_discard(job)
          job.discarded_at = Time.now.utc
          if keep_discarded?
            Arj.save!(job)
          else
            Arj.record_class.find(job_id).destroy!
          end
        end
      end

      # Extends the specified class with {Arj::FailedAt::ClassMethods}.
      #
      # @param clazz [Class]
      # @return [Class]
      def self.included(clazz)
        clazz.extend(Arj::Extensions::KeepDiscarded::ClassMethods)
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
  end
end
