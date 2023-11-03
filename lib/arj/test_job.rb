# frozen_string_literal: true

require 'active_job/base'
require_relative 'persistence'
require_relative 'query_methods'

module Arj
  class TestJob < ActiveJob::Base
    def perform(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      raise(kwargs[:error], 'error') if kwargs[:error]
    end
  end

  class TestJobWithPersistence < TestJob
    include Persistence
  end

  class TestJobWithQuery < TestJob
    include QueryMethods
  end

  class TestError < StandardError; end

  class TestJobWithRetry < TestJob
    retry_on TestError, wait: 1.minute, attempts: 3
  end
end
