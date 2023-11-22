# frozen_string_literal: true

module Arj
  module Extensions
    # Adds a +last_error+ attribute to a job class.
    #
    # Example usage:
    #   class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
    #     def self.up
    #       Arj::Extensions::LastError.migrate_up(self)
    #     end
    #
    #     def self.down
    #       Arj::Extensions::LastError.migrate_down(self)
    #     end
    #   end
    #
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Job
    #     include Arj::Extensions::LastError
    #
    #     retry_on Exception
    #   end
    #
    #   job = SampleJob.perform_now
    #   job.last_error
    module LastError
      # Wraps an error String to prevent the entire message and backtrace from being displayed when pretty printing.
      class Wrapper
        def initialize(clazz, message, backtrace)
          @clazz = clazz
          @message = message
          @backtrace = backtrace
        end

        # Returns a {Wrapper} for the specified error String.
        #
        # @return [Wrapper]
        def self.from(str)
          lines = str.split("\n")
          match = lines.first.match(/^(^[^ ]+): (.*)/)
          raise "invalid error: #{lines.first}" unless match

          Wrapper.new(match[1], match[2], lines[1..])
        end

        # Returns the full error with backtrace.
        #
        # @return [String]
        def to_s
          (["#{@clazz}: #{@message}"] + @backtrace).join("\n")
        end

        # Implemented to truncate errors when pretty printing.
        def pretty_print(pp)
          message = @message.truncate(100, omission: '…')
          message = "#{message} (backtrace hidden)" if @backtrace.any?
          pp.pp("#{@clazz}: #{message}")
        end
      end
      private_constant :Wrapper

      # Returns a String representing the last error encountered during execution, if any.
      #
      # @return [String]
      def last_error
        @last_error&.to_s
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

        error = error&.truncate(10_535, omission: '… (truncated)')

        @last_error = error ? Wrapper.from(error) : nil
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
        unless Arj.record_class.attribute_names.include?('last_error')
          raise "#{Arj.record_class.name} class missing last_error attribute"
        end

        super.merge('last_error' => @last_error)
      end

      # Overridden to add support for deserializing the +last_error+ attribute.
      #
      # @param job_data [Hash]
      def deserialize(job_data)
        raise "#{Arj.record_class.name} data missing last_error attribute" unless job_data.key?('last_error')

        super.tap { self.last_error = job_data['last_error'] }
      end

      # Adds a +last_error+ column to the jobs table.
      #
      # @param migration [Class<ActiveRecord::Migration>]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_up(migration, table_name: :jobs)
        migration.add_column table_name, :last_error, :text
      end

      # Removes the +last_error+ column from the jobs table.
      #
      # @param migration [Class<ActiveRecord::Migration>]
      # @param table_name [Symbol] defaults to +:jobs+
      # @return [NilClass]
      def self.migrate_down(migration, table_name: :jobs)
        migration.remove_column table_name, :last_error
      end
    end
  end
end
