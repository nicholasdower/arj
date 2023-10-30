# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/arj/job'

describe Arj::Job do
  context '.perform_later' do
    subject { TestJob.perform_later(1) }

    it 'enqueues a job' do
      expect { subject }.to change(Job, :count).from(0).to(1)
    end
  end
end
