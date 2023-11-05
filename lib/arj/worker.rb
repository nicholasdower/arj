# frozen_string_literal: true

require 'active_job/base'
require 'logger'
require_relative '../arj'

module Arj
  # Used to retrieve and execute jobs.
  class Worker
    DEFAULT_SLEEP_DELAY = 5.seconds
    private_constant :DEFAULT_SLEEP_DELAY

    attr_reader :description, :sleep_delay
    attr_accessor :logger

    # @param description [String] a description for this worker, used in logs
    # @param source [Proc] a job source
    # @param sleep_delay [ActiveSupport::Duration] sleep duration after executing all available jobs, defaults to 5s
    # @param logger [Logger]
    def initialize(
      description: 'Arj::Worker(*)',
      source: -> { Arj.available.first },
      sleep_delay: DEFAULT_SLEEP_DELAY,
      logger: ActiveJob::Base.logger
    )
      @description = description
      @source = source
      @sleep_delay = sleep_delay
      @logger = logger
    end

    # Executes jobs as they become available.
    def start
      loop do
        work_off
        sleep @sleep_delay.in_seconds
      end
    end

    # Executes any available jobs.
    def work_off
      while execute_next; end
    end

    # Executes the next available job.
    def execute_next
      @logger.info("#{description} - Looking for the next available job")
      if (job = @source.call)
        job.perform_now rescue nil
        true
      else
        @logger.info("#{description} - No available jobs found")
        false
      end
    end
  end
end
