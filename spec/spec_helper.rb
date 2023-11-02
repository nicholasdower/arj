# frozen_string_literal: true

require 'active_job'
require 'active_record'
require 'timecop'
require_relative '../script/init'

RSpec.configure do |config|
  config.formatter = :documentation

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
