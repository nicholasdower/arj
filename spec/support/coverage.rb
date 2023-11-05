# frozen_string_literal: true

if ENV['COVERAGE'] == '1'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::Console]
  )

  SimpleCov.start do
    add_filter 'script/'
  end
end
