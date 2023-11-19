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

class CreateJobs < ActiveRecord::Migration[7.1]
  def self.up
    create_table :jobs, id: :string, primary_key: :job_id do |table|
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

    add_index :jobs, %i[priority scheduled_at enqueued_at]
  end

  def self.down
    drop_table :jobs
  end
end

class AddIdToJobs < ActiveRecord::Migration[7.1]
  def self.up
    Arj::Extensions::Id.migrate_up(self)
  end

  def self.down
    Arj::Extensions::Id.migrate_down(self)
  end
end

class AddShardToJobs < ActiveRecord::Migration[7.1]
  def self.up
    Arj::Extensions::Shard.migrate_up(self)
  end

  def self.down
    Arj::Extensions::Shard.migrate_down(self)
  end
end

class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
  def self.up
    Arj::Extensions::LastError.migrate_up(self)
  end

  def self.down
    Arj::Extensions::LastError.migrate_down(self)
  end
end

class AddRetainDiscardedToJobs < ActiveRecord::Migration[7.1]
  def self.up
    Arj::Extensions::RetainDiscarded.migrate_up(self)
  end

  def self.down
    Arj::Extensions::RetainDiscarded.migrate_down(self)
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
