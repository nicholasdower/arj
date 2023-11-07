# frozen_string_literal: true

require_relative 'spec_helper'

describe 'performing' do
  shared_examples 'perform' do
    before { enqueue }

    context '#perform_now' do
      let(:subject) { job.perform_now }

      context 'original job' do
        let(:job) { original_job }

        it 'returns the result' do
          expect(subject).to eq('some_arg')
        end
      end

      context 'queried job' do
        let(:job) { Arj.last }

        it 'returns the result' do
          expect(subject).to eq('some_arg')
        end
      end
    end

    context '.execute' do
      let(:subject) { Arj::Test::Job.execute(job.serialize) }

      context 'original job' do
        let(:job) { original_job }

        it 'returns the result' do
          expect(subject).to eq('some_arg')
        end
      end

      context 'queried job' do
        let(:job) { Arj.last }

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

    it 'returns the result' do
      expect(subject).to eq('some_arg')
    end
  end

  context '#perform_now' do
    let(:subject) { job.perform_now }

    context 'when the job was not enqueued' do
      let(:job) { Arj::Test::Job.new('some_arg') }

      it 'does not persist a job' do
        expect { subject }.not_to change(Job, :count).from(0)
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

      context 'when the database record no longer exists' do
        before { Job.destroy_all }

        it 'raises' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find Job with 'id'/)
        end
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
