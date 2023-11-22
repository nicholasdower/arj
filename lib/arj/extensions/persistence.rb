# frozen_string_literal: true

require 'active_job'
require 'active_job/base'
require 'active_job/arguments'
require 'active_record'
require 'json'
require_relative '../../arj'

module Arj
  module Extensions
    # ActiveRecord-style persistence methods (+save!+, +update!+, +exists?+, etc.), but for jobs.
    #
    # Example usage
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Job
    #     include Arj::Extensions::Persistence
    #   end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   job.queue_name = 'other queue'
    #   job.save!
    #
    # The {Arj} module provides the same methods but with a job argument.
    #
    # Example usage:
    #   class SampleJob < ActiveJob::Base
    #     include Arj::Job
    #   end
    #
    #   job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
    #   job.queue_name = 'other queue'
    #   Arj.save_job!(job)
    module Persistence
      # @return [Boolean] +true+ if this has a corresponding record in the database
      def exists?
        Arj.job_exists?(self)
      end

      # Reloads the attributes of this job from the database.
      #
      # @return [ActiveJob::Base] the specified job, updated
      def reload
        Arj.reload_job(self)
      end

      # Saves the database record associated with this job. Raises if the record is invalid.
      #
      # @return [Boolean] +true+
      def save!
        Arj.save_job!(self)
      end

      # Updates the database record associated with this job. Raises if the record is invalid.
      #
      # @param attributes [Hash]
      # @return [Boolean] +true+
      def update!(attributes)
        Arj.update_job!(self, attributes)
      end

      # Destroys the database record associated with this job.
      #
      # @return [ActiveJob::Base] the specified job
      def destroy!
        Arj.destroy_job!(self)
      end

      # @return [Boolean] +true+ if the this job has been deleted from the database
      def destroyed?
        Arj.job_destroyed?(self)
      end
    end
  end
end
