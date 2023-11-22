# frozen_string_literal: true

module Arj
  # Registers job callbacks when included in an +ActiveJob::Base+ class.
  #
  # Example usage:
  #   class SampleJob < ActiveJob::Base
  #     include Arj::Job
  #   end
  module Job
    # Registers job callbacks.
    #
    # @param clazz [Class]
    # @return [Class]
    def self.included(clazz)
      clazz.before_perform do |job|
        # Setting successfully_enqueued to false in order to detect when a job is re-enqueued during perform.
        job.successfully_enqueued = false
      end

      clazz.after_perform do |job|
        unless job.successfully_enqueued?
          job.scheduled_at = nil
          job.enqueued_at = nil
          Arj.record_class.find_by(job_id: job.job_id)&.destroy!
        end
      end

      clazz.after_discard do |job, _exception|
        job.scheduled_at = nil
        job.enqueued_at = nil
        if job.class.respond_to?(:on_discard)
          job.class.on_discard(job)
        else
          Arj.record_class.find_by(job_id: job.job_id)&.destroy!
        end
      end
    end
  end
end
