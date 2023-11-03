# frozen_string_literal: true

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

class Job < ActiveRecord::Base
end

class CreateJobs < ActiveRecord::Migration[7.1]
  def self.up
    create_table :jobs do |table|
      table.string   :job_class,            null: false
      table.string   :job_id,               null: false
      table.string   :queue_name
      table.integer  :priority
      table.text     :arguments,            null: false
      table.integer  :executions,           null: false
      table.text     :exception_executions, null: false
      table.string   :locale,               null: false
      table.string   :timezone,             null: false
      table.datetime :enqueued_at,          null: false
      table.datetime :scheduled_at

      table.timestamps
    end
  end

  def self.down
    drop_table :jobs
  end
end

class Db
  FILE = '.test.db'

  def self.create
    raise 'connection already established' if @connected

    destroy
    @connected = true
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: FILE)
    CreateJobs.migrate(:up)
  end

  def self.destroy
    Dir.glob("#{FILE}*").each { |file| File.delete(file)}
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
