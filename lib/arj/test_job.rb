# frozen_string_literal: true

require 'active_job/base'
require_relative 'persistence'

module Arj
  # An Arj job for use during testing and development.
  class TestJob < ActiveJob::Base
    include Persistence
    include QueryMethods

    retry_on Exception

    def perform(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      raise StandardError, kwargs[:error] if kwargs[:error]

      arguments
    end
  end
end
