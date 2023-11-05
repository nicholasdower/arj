# frozen_string_literal: true

require 'active_job/base'
require_relative 'arj/persistence'

# ActiveJob queue adapter for Arj.
#
# If using Rails, configure via Rails::Application:
#
#   class MyApplication < Rails::Application
#     config.active_job.queue_adapter = :arj
#   end
#
# If not using Rails, configure via ActiveJob::Base:
#
#   ActiveJob::Base.queue_adapter = :arj
class ArjAdapter
  # Enqueue a job for immediate execution.
  def enqueue(job)
    raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

    Arj::Persistence.enqueue(job)
  end

  # Enqueue a job for execution at the specified time.
  def enqueue_at(job, timestamp)
    raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

    Arj::Persistence.enqueue(job, timestamp)
  end
end
