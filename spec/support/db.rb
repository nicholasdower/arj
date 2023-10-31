# frozen_string_literal: true

require 'active_record'
require 'fileutils'
require 'sqlite3'
require 'yaml'
require_relative '../../db/create_jobs'
require_relative 'job'

class Db
  def self.reset
    Job.destroy_all
  end

  def self.destroy
    Dir.glob('db/.test.db*').each { |f| FileUtils.rm(f) }
  end

  def self.create
    destroy
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/.test.db')

    ActiveRecord::Base.connection.drop_table(:jobs) if ActiveRecord::Base.connection.table_exists?(:jobs)
    CreateJobs.migrate(:up)
  end
end
