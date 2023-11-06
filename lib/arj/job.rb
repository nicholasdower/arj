# frozen_string_literal: true

module Arj
  # Module prepended to the singleton class of ActiveJob::Base objects in order to override #perform_now.
  #
  # ActiveJob assumes that a job is removed from the queue before it is executed, then re-enqueued on retry. Arj, on the
  # other hand, prefers to only remove jobs from the queue upon completion, so as to avoid data loss.
  #
  # To accomplish the desired behavior, we Arj must override ActiveJob::Base#perform_now to delete the job from the
  # database iff it was not re-enqueued.
  module Job
    # Overrides Active::Job#perform_now to ensure that successful jobs are removed from the queue.
    def perform_now
      self.successfully_enqueued = false
      super
    ensure
      Arj.record_class.find(provider_job_id).destroy! unless successfully_enqueued?
    end
  end
end
