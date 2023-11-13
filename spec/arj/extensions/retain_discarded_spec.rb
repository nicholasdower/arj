# frozen_string_literal: true

require_relative '../../spec_helper'

describe Arj::Extensions::RetainDiscarded do
  # Test that we create the job here if it was never enqueued
  # Test that a discarded job can be re-enqueued
  before do
    stub_const('Arj::RetainDiscardedJob', Class.new(ActiveJob::Base))
    Arj::RetainDiscardedJob.class_eval do
      include Arj
      include Arj::Extensions::RetainDiscarded

      def perform
        raise 'oh, hi'
      end
    end
  end

  context 'when discarded_at added to jobs table' do
    before { TestDb.migrate(AddDiscardedAtToJobs, :up) }

    after do
      Job.destroy_all
      TestDb.migrate(AddDiscardedAtToJobs, :down)
    end

    context 'serialization' do
      let(:job) { Arj::RetainDiscardedJob.perform_later }

      context 'when discarded_at is updated' do
        subject { Arj.update!(job, discarded_at: Time.now.utc) }

        it 'updates discarded_at in the database' do
          subject
          expect(Job.first.discarded_at).to eq(Time.now.utc)
        end

        it "updates the job's discarded_at" do
          expect { subject }.to change(job, :discarded_at).from(nil).to(Time.now.utc)
        end
      end

      context 'when a job class without a shard is persisted' do
        subject { Arj::Test::Job.perform_later }

        it 'successfully persists to the database' do
          expect { subject }.to change(Job, :count).from(0).to(1)
        end
      end
    end

    context 'deserialization' do
      subject { Arj.sole }

      context 'when a job class with discarded_at is retrieved' do
        let(:job) { Arj::RetainDiscardedJob.perform_later }

        before { job.perform_now rescue nil }

        it 'sets discarded_at from the database' do
          expect(subject.discarded_at).to eq(Time.now.utc)
        end
      end

      context 'when a job class without discarded_at is retrieved' do
        before { Arj::Test::Job.set(queue: 'some queue').perform_later }

        it 'successfully reads job data from the database' do
          expect(subject.queue_name).to eq('some queue')
        end
      end
    end

    context '.discarded?' do
      subject { job.discarded? }

      let(:job) { Arj::RetainDiscardedJob.perform_later }

      context 'when the job has been discarded' do
        before { job.perform_now rescue nil }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end
    end

    context 'when a subclass disables retention of discarded jobs' do
      subject { job.perform_now }

      let(:job) { Arj::DoNotRetainDiscardedJob.perform_later }

      before do
        stub_const('Arj::DoNotRetainDiscardedJob', Class.new(Arj::RetainDiscardedJob))
        Arj::DoNotRetainDiscardedJob.class_eval do
          destroy_discarded

          def perform
            raise 'oh, hi'
          end
        end
        job
      end

      it 'raises the error raised by the job' do
        expect { subject }.to raise_error(StandardError, 'oh, hi')
      end

      it 'discards the job' do
        expect { subject rescue nil }.to change(Job, :count).from(1).to(0)
      end
    end

    context 'when a subclass enables retention of discarded jobs' do
      subject { job.perform_now }

      let(:job) { Arj::ButRetainDiscardedJob.perform_later }

      before do
        stub_const('Arj::DoNotRetainDiscardedJob', Class.new(ActiveJob::Base))
        Arj::DoNotRetainDiscardedJob.class_eval do
          include Arj
          include Arj::Extensions::RetainDiscarded

          destroy_discarded

          def perform
            raise 'oh, hi'
          end
        end
        stub_const('Arj::ButRetainDiscardedJob', Class.new(Arj::DoNotRetainDiscardedJob))
        Arj::ButRetainDiscardedJob.class_eval do
          retain_discarded

          def perform
            raise 'oh, hi'
          end
        end
        job
      end

      it 'raises the error raised by the job' do
        expect { subject }.to raise_error(StandardError, 'oh, hi')
      end

      it 'retains the job' do
        expect { subject rescue nil }.not_to change(Job, :count).from(1)
      end
    end
  end

  context 'when shard not added to jobs table' do
    context '#serialize' do
      subject { Arj::RetainDiscardedJob.perform_later.serialize }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'Job class missing discarded_at attribute')
      end
    end

    context '#deserialize' do
      subject { Arj::RetainDiscardedJob.new.deserialize({}) }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'Job data missing discarded_at attribute')
      end
    end
  end
end
