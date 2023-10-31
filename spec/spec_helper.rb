# frozen_string_literal: true

require 'active_job'
require 'active_record'

Dir.glob('lib/**/*.rb').each { |f| require "./#{f}" }
Dir.glob('spec/support/**/*.rb').each { |f| require "./#{f}" }

ActiveRecord::Base.logger = Logger.new($stderr)
ActiveJob::Base.queue_adapter = :arj
Time.zone = 'UTC'
Arj.model_class_name = 'Job'

RSpec.configure do |config|
  config.formatter = :documentation

  config.before(:suite) do
    Db.create
  end

  config.before(:suite) do
    Db.destroy
  end

  config.before do
    Db.reset
  end
end
