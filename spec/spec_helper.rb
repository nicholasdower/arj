# frozen_string_literal: true

require 'active_job'
require 'active_record'
require_relative '../lib/arj'
require_relative '../lib/arj_adapter'
require_relative 'support/db'
require_relative 'support/job'
require_relative 'support/test_job'

ActiveRecord::Base.logger = Logger.new($stderr)
ActiveJob::Base.queue_adapter = :arj
Time.zone = 'UTC'
Arj.model_class_name = 'Job'

RSpec.configure do |config|
  config.formatter = :documentation

  config.before(:suite) do
    Db.recreate
  end

  config.before do
    Db.reset
  end
end
