# frozen_string_literal: true

require 'logger'

module Arj
  # A worker which performs jobs.
  class Worker
    attr_reader :queue_name, :max_executions, :sleep_delay
    attr_accessor :logger

    def initialize(queue_name: nil, max_executions: nil, sleep_delay: 5, logger: ActiveJob::Base.logger)
      @queue_name = queue_name
      @max_executions = max_executions
      @sleep_delay = sleep_delay
      @logger = logger
    end

    def start
      loop do
        if (job = next_job)
          job.perform_now
        else
          @logger.info("Arj::Worker(#{@queue_name || '*'}) - No available jobs found, sleeping")
          sleep @sleep_delay
        end
      end
    end

    def work_off
      while (job = next_job)
        job.perform_now
      end
      @logger.info("Arj::Worker(#{@queue_name || '*'}) - No available jobs found")
      nil
    end

    private

    def next_job
      @logger.info("Arj::Worker(#{@queue_name || '*'}) - Looking for the next available job")
      Arj.next(queue_name: @queue_name, max_executions: @max_executions)
    end
  end
end
