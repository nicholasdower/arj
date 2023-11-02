# frozen_string_literal: true

# ActiveJob queue adapter. Set via Rails config:
#
#   config.active_job.queue_adapter = :arj
class ArjAdapter
  def enqueue(job)
    raise "expected ArjJob, found #{job.class}" unless job.is_a?(Arj::Base)

    job.enqueue_record!
  end

  def enqueue_at(job, timestamp)
    raise "expected ArjJob, found #{job.class}" unless job.is_a?(Arj::Base)

    job.enqueue_record!(timestamp)
  end
end
