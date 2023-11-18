# frozen_string_literal: true

require 'active_job'
require 'active_job/base'
require 'active_record'
require 'fileutils'
require 'logger'
require 'sqlite3'
require 'tempfile'

Dir.glob('lib/**/*.rb').each { |f| require "./#{f}" }

ActiveJob::Base.queue_adapter = :arj
Time.zone = 'UTC'

level = Integer(ENV.fetch('LEVEL', Logger::INFO))
ActiveRecord::Base.logger ||= Logger.new(STDOUT, level: level)
ActiveRecord::Base.logger.level = level
ActiveJob::Base.logger ||= Logger.new(STDOUT)
ActiveJob::Base.logger.level = level
ActiveRecord::Migration.verbose = false unless level <= 1

class Job < ActiveRecord::Base
  def self.implicit_order_column
    %w[id created_at enqueued_at].find { attribute_names.include?(_1) }
  end

  def to_arj
    Arj.from(self)
  end
end

def add_default_jobs_columns(table)
  table.string   :job_class,            null: false
  table.string   :queue_name
  table.integer  :priority
  table.text     :arguments,            null: false
  table.integer  :executions,           null: false
  table.text     :exception_executions, null: false
  table.string   :locale
  table.string   :timezone
  table.datetime :enqueued_at,          null: false
  table.datetime :scheduled_at
end

class CreateJobs < ActiveRecord::Migration[7.1]
  def self.up
    create_table :jobs, id: :string, primary_key: :job_id do |table|
      add_default_jobs_columns(table)
    end
    add_index :jobs, [ :priority, :scheduled_at, :enqueued_at ]
  end

  def self.down
    drop_table :jobs
  end
end

class CreateJobsWithId < ActiveRecord::Migration[7.1]
  def self.up
    create_table :jobs do |table|
      table.string :job_id, null: false
      add_default_jobs_columns(table)
    end
    add_index :jobs, :job_id, unique: true
    add_index :jobs, [ :priority, :scheduled_at, :enqueued_at ]
  end

  def self.down
    drop_table :jobs
  end
end

class AddShardToJobs < ActiveRecord::Migration[7.1]
  def self.up
    add_column :jobs, :shard, :string
  end

  def self.down
    remove_column :jobs, :shard
  end
end

class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
  def self.up
    add_column :jobs, :last_error, :text
  end

  def self.down
    remove_column :jobs, :last_error
  end
end

class AddDiscardedAtToJobs < ActiveRecord::Migration[7.1]
  def self.up
    add_column :jobs, :discarded_at, :datetime
    change_column :jobs, :enqueued_at, :datetime, null: true
  end

  def self.down
    remove_column :jobs, :discarded_at
    change_column :jobs, :enqueued_at, :datetime, null: false
  end
end

class TestDb
  FILE = '.test.db'

  def self.create
    raise 'connection already established' if @connected

    self.destroy
    @connected = true
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: FILE)
    CreateJobs.migrate(:up)
  end

  def self.migrate(migration, direction)
    migration.migrate(direction)
    Job.reset_column_information
  end

  def self.destroy
    Dir.glob("#{FILE}*").each { |file| File.delete(file)}
    @connected = false
  end

  def self.reset
    self.destroy
    self.create
  end

  def self.clear
    raise 'connection not established' unless @connected

    Job.destroy_all
  end
end
