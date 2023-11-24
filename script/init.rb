# frozen_string_literal: true

require 'active_job'
require 'active_job/base'
require 'active_record'
require 'fileutils'
require 'logger'
require 'tempfile'

Dir.glob('lib/**/*.rb').each { |f| require "./#{f}" }

ActiveJob::Base.queue_adapter = :arj
Time.zone = 'UTC'

level = Integer(ENV.fetch('LEVEL', Logger::INFO))
ActiveRecord::Base.logger ||= Logger.new($stdout, level: level)
ActiveRecord::Base.logger.level = level
ActiveJob::Base.logger ||= Logger.new($stdout)
ActiveJob::Base.logger.level = level
ActiveRecord::Migration.verbose = false unless level <= 1

class Job < ActiveRecord::Base
  include Arj::Record
  extend Arj::Documentation::ArjRecord
end

class CreateJobs < ActiveRecord::Migration[7.1]
  def self.up
    create_table :jobs, id: :string, primary_key: :job_id do |table|
      table.string   :job_class, null: false
      table.string   :queue_name
      table.integer  :priority
      table.text     :arguments,            null: false
      table.integer  :executions,           null: false
      table.text     :exception_executions, null: false
      table.string   :locale
      table.string   :timezone
      table.datetime :enqueued_at, null: false
      table.datetime :scheduled_at
    end

    add_index :jobs, %i[priority scheduled_at]
    add_index :jobs, %i[enqueued_at]
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
    connect

    ActiveRecord::Base.connection.drop_table(:jobs) if ActiveRecord::Base.connection.table_exists?(:jobs)

    CreateJobs.migrate(:up)
  end

  def self.connect
    raise 'connection already established' if @connected

    @connected = true
    db = ENV.fetch('DB', 'sqlite')
    case db
    when 'mysql'
      require 'mysql2'
      ActiveRecord::Base.establish_connection(
        adapter:  'mysql2', host: '127.0.0.1', username: 'root', password: 'root', database: 'arj'
      )
    when 'postgresql', 'postgres', 'pg'
      require 'pg'
      ActiveRecord::Base.establish_connection(
        adapter:  'postgresql', host: '127.0.0.1', username: 'root', password: 'root', database: 'arj'
      )
    when 'sqlite'
      require 'sqlite3'
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: FILE)
    else
      raise "invalid database: #{db}"
    end
  end

  def self.migrate(migration, direction)
    migration.migrate(direction)
    Job.reset_column_information
  end

  def self.destroy
    ActiveRecord::Base.connection.drop_table(:jobs) if @connected && ActiveRecord::Base.connection.table_exists?(:jobs)
    Dir.glob("#{FILE}*").each { |file| File.delete(file) }
    @connected = false
  end

  def self.reset
    destroy
    create
  end

  def self.clear
    raise 'connection not established' unless @connected

    Job.destroy_all
  end
end
