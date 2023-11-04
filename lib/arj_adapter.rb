# frozen_string_literal: true

require 'active_job/base'
require_relative 'arj/persistence'

class ArjAdapter
  def enqueue(job)
    raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

    Arj::Persistence.enqueue(job)
  end

  def enqueue_at(job, timestamp)
    raise "expected ActiveJob::Base, found #{job.class}" unless job.is_a?(ActiveJob::Base)

    Arj::Persistence.enqueue(job, timestamp)
  end
end
