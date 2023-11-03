# frozen_string_literal: true

require 'active_job/base'
require_relative 'persistence'
require_relative 'query_methods'

module Arj
  class TestJob < ActiveJob::Base
    def perform(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      raise(kwargs[:error], kwargs[:message] || 'error') if kwargs[:error]

      case arguments.size
      when 0
        nil
      when 1
        arguments.sole
      else
        arguments
      end
    end
  end

  class TestJobWithPersistence < TestJob
    include Persistence
  end

  class TestJobWithQuery < TestJob
    include QueryMethods
  end

  class RetryError < StandardError; end

  class TestJobWithRetry < TestJob
    retry_on RetryError, wait: 1.minute, attempts: 2
  end
end
