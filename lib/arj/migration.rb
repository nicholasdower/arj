# frozen_string_literal: true

require 'active_record/migration'

module Arj
  # Provides migration classes used to add/customize the jobs table.
  #
  # Example usage:
  #   # Create the default jobs table.
  #   class CreateJobs < Arj::Migration[7.1]
  #     def self.up
  #       create_jobs_table
  #     end
  #
  #     def self.down
  #       drop_table :jobs
  #     end
  #   end
  #
  #  # Alternatively, create the jobs table with one or more extensions.
  #  class CreateJobsWithExtensions < Arj::Migration[7.1]
  #    def self.up
  #      create_jobs_table(extensions: [:id, :shard, :last_error, :retain_discarded])
  #    end
  #
  #    def self.down
  #      drop_table :jobs
  #    end
  #  end
  #
  #  # Update an existing table, for instance to add the shard column used by {Arj::Extensions::Shard}.
  #  class AddShardToJobs < Arj::Migration[7.1]
  #    def self.up
  #      add_shard_column
  #    end
  #
  #    def self.down
  #      remove_shard_column
  #    end
  #  end
  module Migration
    EXTENSIONS = %i[id shard last_error retain_discarded].freeze
    private_constant :EXTENSIONS

    # rubocop:disable Naming/ClassAndModuleCamelCase

    # ActiveRecord 7.1 Migration
    class V7_1 < ActiveRecord::Migration::Compatibility::V7_1
      class << self
        # Creates the jobs table.
        #
        # @param table_name [Symbol] optional override for default table name
        # @param extensions [Array<Symbol>] optional extension columns, e.g. :id, :shard, :last_error, :retain_discarded
        # @yield [ActiveRecord::ConnectionAdapters::TableDefinition]
        # @return [NilClass]
        def create_jobs_table(table_name: :jobs, extensions: [], &block)
          extensions = extensions.map(&:to_sym)
          raise "duplicate extras found: #{extensions}" if extensions.uniq != extensions
          raise "invalid extras found: #{extensions}" unless (extensions - EXTENSIONS).empty?

          table_def_block = proc do |table|
            table.string   :job_class, null: false
            table.string   :queue_name
            table.integer  :priority
            table.text     :arguments,            null: false
            table.integer  :executions,           null: false
            table.text     :exception_executions, null: false
            table.string   :locale
            table.string   :timezone
            table.datetime :enqueued_at, null: extensions.include?(:retain_discarded)
            table.datetime :scheduled_at

            table.string   :shard        if extensions.include?(:shard)
            table.text     :last_error   if extensions.include?(:last_error)
            table.datetime :discarded_at if extensions.include?(:retain_discarded)

            block&.call(table)
          end

          if extensions.include?(:id)
            create_table table_name do |table|
              table.string :job_id, null: false
              table_def_block.call(table)
            end
            add_index :jobs, :job_id, unique: true
          else
            create_table table_name, id: :string, primary_key: :job_id do |table|
              table_def_block.call(table)
            end
          end

          add_index table_name, %i[priority scheduled_at enqueued_at]
          nil
        end

        # Adds the +shard+ column.
        #
        # @see Arj::Extensions::Shard
        # @return [NilClass]
        def add_shard_extension(table_name: :jobs)
          add_column table_name, :shard, :string
          nil
        end

        # Removes the +shard+ column.
        #
        # @see Arj::Extensions::Shard
        # @return [NilClass]
        def remove_shard_extension(table_name: :jobs)
          remove_column table_name, :shard
          nil
        end

        # Adds the +last_error+ column.
        #
        # @see Arj::Extensions::LastError
        # @return [NilClass]
        def add_last_error_extension(table_name: :jobs)
          add_column table_name, :last_error, :text
          nil
        end

        # Removes the +last_error+ column.
        #
        # @see Arj::Extensions::LastError
        # @return [NilClass]
        def remove_last_error_extension(table_name: :jobs)
          remove_column table_name, :last_error
          nil
        end

        # Adds the +discarded_at+ column and changes the +enqueued_at+ column to allow +null+.
        #
        # @return [NilClass]
        def add_retain_discarded_extension(table_name: :jobs)
          add_column table_name, :discarded_at, :datetime
          change_column table_name, :enqueued_at, :datetime, null: true
          nil
        end

        # Removes the +discarded_at+ column and changes the +enqueued_at+ column to disallow +null+.
        #
        # @see Arj::Extensions::RetainDiscarded
        # @return [NilClass]
        def remove_retain_discarded_extension(table_name: :jobs)
          remove_column table_name, :discarded_at
          change_column table_name, :enqueued_at, :datetime, null: false
          nil
        end
      end
    end

    # rubocop:enable Naming/ClassAndModuleCamelCase

    class << self
      # Accessor for versioned migration classes.
      #
      # @return [ActiveRecord::Migration]
      def [](version)
        case version.to_s
        when '7.1'
          V7_1
        else
          raise "Unsupported version: #{version}"
        end
      end
    end
  end
end
