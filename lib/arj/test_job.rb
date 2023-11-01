# frozen_string_literal: true

module Arj
  # An Arj job for use during testing and development.
  class TestJob < Arj::Base
    rescue_from(Exception) do |_error|
      retry_job
    end

    def retry_job(options = {})
      options[:wait] = 5 + (executions**4) unless options[:wait] || options[:wait_until]
      super
    end

    def perform(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      raise StandardError, kwargs[:error] if kwargs[:error]

      arguments
    end
  end
end
