# frozen_string_literal: true

require 'active_job/base'
require 'logger'
require_relative '../arj'

module Arj
  class Worker
    attr_reader :queue_name, :max_executions, :sleep_delay
    attr_accessor :logger

    def self.next_job(queue_name: nil, max_executions: nil)
      relation = Arj.where('scheduled_at is null or scheduled_at < ?', Time.zone.now)
      relation = relation.where(queue_name:) if queue_name
      relation = relation.where('executions < ?', max_executions) if max_executions
      relation.order(priority: :asc, scheduled_at: :asc).first
    end

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
      Arj::Worker.next_job(queue_name: @queue_name, max_executions: @max_executions)
    end
  end
end
