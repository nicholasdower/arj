# frozen_string_literal: true

require_relative 'spec_helper'

describe 'performing' do
  shared_examples 'perform' do
    before { enqueue }

    context '#perform_now' do
      let(:subject) { job.perform_now }

      context 'original job' do
        let(:job) { original_job }

        it 'executes the job' do
          expect { subject }.to change { job.global_executions }.from(0).to(1)
        end

        it 'returns the result' do
          expect(subject).to eq('some_arg')
        end
      end

      context 'queried job' do
        let(:job) { Arj.last }

        it 'executes the job' do
          expect { subject }.to change { job.global_executions }.from(0).to(1)
        end

        it 'returns the result' do
          expect(subject).to eq('some_arg')
        end
      end
    end

    context '.execute' do
      let(:subject) { Arj::Test::Job.execute(job.serialize) }

      context 'original job' do
        let(:job) { original_job }

        it 'executes the job' do
          expect { subject }.to change { job.global_executions }.from(0).to(1)
        end

        it 'returns the result' do
          expect(subject).to eq('some_arg')
        end
      end

      context 'queried job' do
        let(:job) { Arj.last }

        it 'executes the job' do
          expect { subject }.to change { job.global_executions }.from(0).to(1)
        end

        it 'returns the result' do
          expect(subject).to eq('some_arg')
        end
      end
    end
  end

  context '.perform_now' do
    let(:subject) { Arj::Test::Job.perform_now('some_arg') }

    it 'does not persist a job' do
      expect { subject }.not_to change(Job, :count).from(0)
    end

    it 'executes the job' do
      expect { subject }.to change { Arj::Test::Job.global_executions.values.sum }.from(0).to(1)
    end

    it 'returns the result' do
      expect(subject).to eq('some_arg')
    end

    context 'when the job enqueues itself while executing' do
      let(:subject) { Arj::SampleJob.perform_now }

      before do
        stub_const('Arj::SampleJob', Class.new(ActiveJob::Base))
        Arj::SampleJob.class_eval do
          include Arj

          def perform
            enqueue
          end
        end
      end

      it 'enqueues the job' do
        expect { subject }.to change(Job, :count).from(0).to(1)
      end
    end
  end

  context '#perform_now' do
    let(:subject) { job.perform_now }

    context 'when the job was not enqueued' do
      let(:job) { Arj::Test::Job.new('some_arg') }

      it 'does not persist a job' do
        expect { subject }.not_to change(Job, :count).from(0)
      end

      it 'executes the job' do
        expect { subject }.to change { job.global_executions }.from(0).to(1)
      end

      it 'returns the result' do
        expect(subject).to eq('some_arg')
      end
    end

    context 'when the job is re-enqueued' do
      let!(:job) { Arj::Test::Job.perform_later(Arj::Test::Error) }

      it 'does not delete the database record' do
        expect { subject }.not_to change(Job, :count).from(1)
      end
    end

    context 'when re-enqueuing fails' do
      let!(:job) { Arj::Test::Job.perform_later(Arj::Test::Error) }

      before do
        allow(ActiveJob::Base.queue_adapter).to receive(:enqueue_at).and_raise(StandardError, 'enqueue failed')
      end

      it 'does not delete the database record' do
        expect { subject rescue nil }.not_to change(Job, :count).from(1)
      end
    end

    context 'when the job is not re-enqueued' do
      let!(:job) { Arj::Test::Job.perform_later }

      it 'deletes the database record' do
        expect { subject }.to change(Job, :count).from(1).to(0)
      end

      context 'when scheduled_at is set' do
        let!(:job) { Arj::Test::Job.set(wait_until: 1.second.ago).perform_later }

        it 'clears scheduled_at' do
          expect { subject }.to change { job.scheduled_at&.to_s }.from(1.second.ago.to_s).to(nil)
        end
      end

      it 'clears enqueued_at' do
        expect { subject }.to change { job.enqueued_at&.to_s }.from(Time.now.utc.to_s).to(nil)
      end

      context 'when the database record no longer exists' do
        before { Job.destroy_all }

        it 'does not raise' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'when the job re-enqueues itself while executing' do
      let!(:job) { Arj::Test::Job.perform_later(-> { job.enqueue }) }

      it 'does not delete the database record' do
        expect { subject }.not_to change(Job, :count).from(1)
      end
    end
  end

  context '.perform_later' do
    let(:original_job) { Arj::Test::Job.perform_later('some_arg') }
    let(:enqueue) { original_job }

    include_examples 'perform'
  end

  context '.enqueue' do
    let(:original_job) { Arj::Test::Job.new('some_arg') }
    let(:enqueue) { original_job.enqueue }

    include_examples 'perform'
  end

  context '.perform_all_later' do
    let(:original_job) { Arj::Test::Job.new('some_arg') }
    let(:enqueue) { ActiveJob.perform_all_later(original_job) }

    include_examples 'perform'
  end
end
