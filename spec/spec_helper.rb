# frozen_string_literal: true

require 'active_job'
require 'active_record'
require 'timecop'
require_relative '../script/init'

RSpec.configure do |config|
  config.formatter = :documentation

  config.before(:suite) do
    Db.instance.create
  end

  config.after(:suite) do
    Db.instance.destroy
  end

  config.before do
    Db.instance.reset
    Timecop.freeze
  end

  config.after do
    Timecop.return
  end
end
