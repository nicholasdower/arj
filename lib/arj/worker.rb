# frozen_string_literal: true

require 'active_job/base'
require 'logger'
require_relative '../arj'

module Arj
  class Worker
    attr_reader :description, :sleep_delay
    attr_accessor :logger

    def initialize(
      description: 'Arj::Worker(*)',
      source: -> { Arj.next },
      sleep_delay: 5.seconds,
      logger: ActiveJob::Base.logger
    )
      @description = description
      @source = source
      @sleep_delay = sleep_delay
      @logger = logger
    end

    def start
      loop do
        work_off
        sleep @sleep_delay.in_seconds
      end
    end

    def work_off
      while perform_next; end
    end

    def perform_next
      if (job = next_job)
        job.perform_now rescue nil
        true
      else
        @logger.info("#{description} - No available jobs found")
        false
      end
    end

    private

    def next_job
      @logger.info("#{description} - Looking for the next available job")
      @source.call
    end
  end
end
