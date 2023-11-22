# frozen_string_literal: true

require_relative '../../spec_helper'

describe Arj::Extensions::Timeout do
  subject { job.perform_now }

  let(:enqueue) { Arj::JobWithTimeout.perform_later }
  let(:job) { enqueue }

  before do
    stub_const('Arj::JobWithTimeout', Class.new(ActiveJob::Base))
    Arj::JobWithTimeout.class_eval do
      include Arj::Job
      include Arj::Extensions::Timeout

      def perform; end
    end

    allow(Timeout).to receive(:timeout).and_raise(Arj::Extensions::Timeout::Error.new('execution expired'))

    enqueue
  end

  context 'with retries' do
    before do
      Arj::JobWithTimeout.class_eval do
        retry_on Arj::Extensions::Timeout::Error, wait: 1.minute, attempts: 2
      end
    end

    it 're-enqueues the job' do
      expect { subject }.to change { Job.sole.executions }.from(0).to(1)
    end

    it 'does not raise' do
      expect { subject }.not_to raise_error
    end
  end

  context 'without retries' do
    it 'discards the job' do
      expect { subject rescue nil }.to change(Job, :count).from(1).to(0)
    end

    it 'raises' do
      expect { subject }.to raise_error(Arj::Extensions::Timeout::Error, 'execution expired')
    end
  end

  context 'when timeout not set for job class' do
    it 'uses the default timeout' do
      expect(Timeout).to receive(:timeout).with(300, Arj::Extensions::Timeout::Error, 'execution expired')
      expect { subject }.to raise_error(Arj::Extensions::Timeout::Error, 'execution expired')
    end

    context 'when default timeout overridden' do
      before { Arj::Extensions::Timeout.default_timeout = 10.minutes }
      after { Arj::Extensions::Timeout.default_timeout = 5.minutes }

      it 'uses the overridden default timeout' do
        expect(Timeout).to receive(:timeout).with(600, Arj::Extensions::Timeout::Error, 'execution expired')
        expect { subject }.to raise_error(Arj::Extensions::Timeout::Error, 'execution expired')
      end
    end
  end

  context 'when timeout is set for job class' do
    before do
      Arj::JobWithTimeout.class_eval do
        timeout_after 1.minute
      end
    end

    it 'uses the class timeout' do
      expect(Timeout).to receive(:timeout).with(60, Arj::Extensions::Timeout::Error, 'execution expired')
      expect { subject }.to raise_error(Arj::Extensions::Timeout::Error, 'execution expired')
    end
  end
end
