# frozen_string_literal: true

module Arj
  # An Arj job for use during testing and development.
  class TestJob < Arj::Base
    retry_on Exception

    def perform(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      raise StandardError, kwargs[:error] if kwargs[:error]

      arguments
    end
  end
end
