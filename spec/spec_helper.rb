# frozen_string_literal: true

require_relative 'support/coverage' if ENV['COVERAGE'] == '1'

require 'active_job'
require 'active_record'
require 'awesome_print'
require 'logger'
require 'timecop'

ENV['LEVEL'] ||= Logger::FATAL.to_s

require_relative '../script/init'

Dir.glob('spec/support/**/*.rb').each { |f| require "./#{f}" }

RSpec.configure do |config|
  config.before(:suite) do
    Db.create
  end

  config.after(:suite) do
    Db.destroy
  end

  config.before do
    Db.clear
    Timecop.freeze
  end

  config.after do
    Timecop.return
  end
end
