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

class CreateJobs < Arj::Migration[7.1]
  def self.up
    create_jobs_table
  end

  def self.down
    drop_table :jobs
  end
end

class CreateJobsWithId < Arj::Migration[7.1]
  def self.up
    create_jobs_table(extensions: [:id])
  end

  def self.down
    drop_table :jobs
  end
end

class AddShardToJobs < Arj::Migration[7.1]
  def self.up
    add_shard_extension
  end

  def self.down
    remove_shard_extension
  end
end

class AddLastErrorToJobs < Arj::Migration[7.1]
  def self.up
    add_last_error_extension
  end

  def self.down
    remove_last_error_extension
  end
end

class AddRetainDiscardedToJobs < Arj::Migration[7.1]
  def self.up
    add_retain_discarded_extension
  end

  def self.down
    remove_retain_discarded_extension
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
