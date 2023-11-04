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

  context '.perform_now' do
    let(:subject) { Arj::Test::Job.new('some_arg').perform_now }

    it 'does not persist a job' do
      expect { subject }.not_to change(Job, :count).from(0)
    end

    it 'returns the result' do
      expect(subject).to eq('some_arg')
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
