# frozen_string_literal: true

require 'active_record'
require 'sqlite3'
require 'yaml'
require_relative '../../db/migrate/20231030232800_create_jobs'
require_relative 'job'

class Db
  def self.reset
    Job.destroy_all
  end

  def self.recreate
    ActiveRecord::Base.establish_connection(YAML.load(File.open('database.yml')))

    ActiveRecord::Base.connection.drop_table(:jobs) if ActiveRecord::Base.connection.table_exists?(:jobs)
    CreateJobs.migrate(:up)
  end
end
