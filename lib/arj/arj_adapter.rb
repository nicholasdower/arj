# frozen_string_literal: true

require 'active_job'
require 'active_job/base'
require 'arj'

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
  #
  # @param job [ActiveJob::Base] the job to enqueue
  # @return [ActiveJob::Base] the enqueued job
  def enqueue(job)
    raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

    Arj.enqueue(job)
  end

  # Enqueue a job for execution at the specified time.
  #
  # @param job [ActiveJob::Base] the job to enqueue
  # @param timestamp [Numeric, NilClass] optional number of seconds since Unix epoch at which to execute the job
  # @return [ActiveJob::Base] the enqueued job
  def enqueue_at(job, timestamp)
    raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

    Arj.enqueue(job, timestamp)
  end
end
