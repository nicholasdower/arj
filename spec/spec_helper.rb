# frozen_string_literal: true

require_relative 'support/coverage' if ENV['COVERAGE'] == '1'

require 'awesome_print'
require 'logger'
require 'pry'
require 'timecop'

ENV['LEVEL'] ||= Logger::FATAL.to_s

require_relative '../script/init'

Dir.glob('spec/support/**/*.rb').each { |f| require "./#{f}" }

RSpec.configure do |config|
  config.before(:suite) do
    TestDb.create
  end

  config.after(:suite) do
    TestDb.destroy
  end

  config.before do
    TestDb.clear
    Timecop.freeze
  end

  config.after do
    Timecop.return
    Arj::Test::Job.reset
  end
end
