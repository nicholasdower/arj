# frozen_string_literal: true

# ActiveJob queue adapter. Set via Rails config:
#
#   config.active_job.queue_adapter = :arj
class ArjAdapter
  def enqueue(job)
    raise "expected ArjJob, found #{job.class}" unless job.is_a?(Arj::Base)

    job.arj_enqueue!
  end

  def enqueue_at(job, timestamp)
    raise "expected ArjJob, found #{job.class}" unless job.is_a?(Arj::Base)

    job.arj_enqueue!(timestamp)
  end
end
