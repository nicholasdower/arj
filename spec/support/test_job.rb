# frozen_string_literal: true

require 'active_record'

require_relative 'job'
require_relative '../../lib/arj/job'

# Arj job for use in tests.
class TestJob < Arj::Job
  self.arj_record_class = Job

  rescue_from(Exception) do |_error|
    retry_job
  end

  def retry_job(options = {})
    options[:wait] = 5 + (executions**4) unless options[:wait] || options[:wait_until]
    super
  end

  def perform(*args, **kwargs)
    ActiveJob::Base.logger.info "Arj::TestJob#perform #{job_id} - args: #{args}, kwargs: #{kwargs}"
    raise StandardError, kwargs[:error] if kwargs[:error]
  end
end
