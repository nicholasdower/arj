# frozen_string_literal: true

module Arj
  module Extensions
    # Adds a +last_error+ attribute to a job class.
    #
    # Example usage:
    #   class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
    #     def change
    #       add_column :jobs, :last_error, :text
    #     end
    #   end
    #
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Extensions::LastError
    #
    #     retry_on Exception
    #   end
    #
    #   job = SampleJob.perform_later
    #   job.perform_now
    #   puts job.last_error
    module LastError
      # Returns a String representing the last error encountered during execution, if any.
      #
      # @return [String]
      def last_error
        @last_error
      end

      # Sets the last error.
      #
      # @param error [String, Exception]
      # @return [String]
      def last_error=(error)
        unless error.nil? || error.is_a?(Exception) || error.is_a?(String)
          raise ArgumentError, "invalid error: #{error.class}"
        end

        if error.is_a?(Exception)
          backtrace = error.backtrace&.map { |line| "\t#{line}" }&.join("\n")
          error = backtrace ? "#{error.class}: #{error.message}\n#{backtrace}" : "#{error.class}: #{error.message}"
        end

        @last_error = error&.truncate(10_535, omission: '… (truncated)')
      end

      # Overridden to add support for setting the +last_error+ attribute.
      #
      # @param options [Hash]
      # @return [ActiveJob::ConfiguredJob]
      def set(options = {})
        super.tap do
          self.last_error = options[:error] if options[:error]
        end
      end

      # Overridden to add support for serializing the +last_error+ attribute.
      #
      # @return [Hash]
      def serialize
        super.merge('last_error' => @last_error)
      end

      # Overridden to add support for deserializing the +last_error+ attribute.
      #
      # @param job_data [Hash]
      def deserialize(job_data)
        super.tap { @last_error = job_data['last_error'] }
      end
    end
  end
end
