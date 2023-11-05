# frozen_string_literal: true

require_relative '../../spec_helper'

describe Arj::Extensions::LastError do
  before do
    TestDb.migrate(AddLastErrorToJobs, :up)
    stub_const('Arj::JobWithLastError', Class.new(ActiveJob::Base))
    Arj::JobWithLastError.class_eval do
      include Arj::Extensions::LastError
      retry_on Exception

      def perform
        raise 'oh, hi'
      end
    end
  end

  after { TestDb.migrate(AddLastErrorToJobs, :down) }

  context 'serialization' do
    context 'when a job fails' do
      subject { job.perform_now }

      let(:job) { Arj::JobWithLastError.perform_later }

      it 'persists the last error' do
        subject
        expect(Job.last.last_error).to match(/RuntimeError: oh, hi/)
      end
    end

    context 'when error is updated' do
      subject { Arj.update!(job, last_error: error) }

      let!(:job) { Arj::JobWithLastError.perform_later }
      let(:error) do
        raise 'oh, hi'
      rescue RuntimeError => e
        return e
      end

      it 'persists the last error' do
        expect { subject }.to change { Job.sole.last_error }.from(nil).to(/RuntimeError: oh, hi/)
      end

      context 'when error is too long' do
        let(:error) do
          super().tap do |e|
            e.backtrace.clear
            1_000.times { e.backtrace << '0123456789' }
          end
        end

        it 'persists the last error truncated' do
          subject
          expect(Job.sole.last_error).to end_with('… (truncated)')
        end
      end

      context 'when error is not a String or Exception' do
        let(:error) { Object.new }

        it 'raises' do
          expect { subject }.to raise_error('invalid error: Object')
        end
      end

      context 'when error is nil' do
        let(:error) { nil }

        it 'persists the last error' do
          subject
          expect(Job.sole.last_error).to be_nil
        end
      end
    end
  end

  context 'deserialization' do
    subject { Arj.last }

    context 'when a job class with last_error is retrieved' do
      before { Arj::JobWithLastError.perform_now }

      it 'sets the last_error from the database' do
        expect(subject.last_error).to match(/RuntimeError: oh, hi/)
      end
    end

    context 'when a job class without a last_error is retrieved' do
      subject { Arj::Test::Job.set(queue: 'some queue').perform_later }

      it 'successfully reads job data from the database' do
        expect(subject.queue_name).to eq('some queue')
      end
    end
  end
end
