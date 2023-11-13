# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj::Test do
  context '.all' do
    subject { Arj::Test.all }

    before do
      stub_const('Arj::SampleJob', Class.new(ActiveJob::Base))
      Arj::SampleJob.include(Arj)
      Arj::Test::Job.perform_later
      Arj::SampleJob.perform_later
    end

    it 'returns Arj::Test::Jobs' do
      expect(subject.size).to eq(1)
      expect(subject.sole).to be_a(Arj::Test::Job)
    end
  end

  describe Arj::Test::Job do
    context '#perform_now' do
      subject { job.perform_now }

      let(:job) { Arj::Test::Job.perform_later(*arguments) }

      context 'when zero arguments specified' do
        let(:arguments) { [] }

        it 'returns nil' do
          expect(subject).to be_nil
        end

        it 'deletes the job' do
          expect { subject rescue nil }.to change { Job.exists?(job.job_id) }.from(true).to(false)
        end
      end

      context 'when single argument specified' do
        let(:arguments) { [1] }

        it 'returns the argument' do
          expect(subject).to eq(1)
        end

        it 'deletes the job' do
          expect { subject rescue nil }.to change { Job.exists?(job.job_id) }.from(true).to(false)
        end
      end

      context 'when multiple arguments specified' do
        let(:arguments) { [1, 2] }

        it 'returns the arguments' do
          expect(subject).to eq([1, 2])
        end

        it 'deletes the job' do
          expect { subject rescue nil }.to change { Job.exists?(job.job_id) }.from(true).to(false)
        end
      end

      context 'when error specified' do
        let(:arguments) { [StandardError] }

        it 'raises' do
          expect { subject }.to raise_error(StandardError, 'error')
        end

        it 'deletes the job' do
          expect { subject rescue nil }.to change { Job.exists?(job.job_id) }.from(true).to(false)
        end
      end

      context 'when error and message specified' do
        let(:arguments) { [StandardError, 'oh, hi'] }

        it 'raises' do
          expect { subject }.to raise_error(StandardError, 'oh, hi')
        end

        it 'deletes the job' do
          expect { subject rescue nil }.to change { Job.exists?(job.job_id) }.from(true).to(false)
        end
      end

      context 'when Arj::Test::Error specified' do
        let(:arguments) { [Arj::Test::Error] }

        it 'returns an error' do
          expect(subject).to be_a(Arj::Test::Error)
        end

        it 're-enqueues the job' do
          expect { subject }.not_to change { Job.exists?(job.job_id) }.from(true)
        end
      end

      context 'when Proc specified' do
        let(:arguments) { [-> { 'some val' }] }

        it 'returns the result' do
          expect(subject).to eq('some val')
        end

        it 'deletes the job' do
          expect { subject rescue nil }.to change { Job.exists?(job.job_id) }.from(true).to(false)
        end
      end
    end

    context '#on_perform' do
      let(:job) { Arj::Test::Job.perform_later(Arj::Test::Error) }

      it 'updates the perform method' do
        expect(job.perform_now).to be_a(Arj::Test::Error)
        job.on_perform { 'some val' }
        expect(job.perform_now).to eq('some val')
      end
    end

    context '#global_executions' do
      it 'returns the global executions for a job' do
        job = Arj::Test::Job.perform_later(Arj::Test::Error)
        expect(job.global_executions).to eq(0)
        job.perform_now
        expect(job.global_executions).to eq(1)
        expect { job.perform_now }.to raise_error(Arj::Test::Error)
        expect(job.global_executions).to eq(2)
      end
    end

    context '.total_executions' do
      it 'returns the total executions for all jobs' do
        expect(Arj::Test::Job.total_executions).to eq(0)
        Arj::Test::Job.perform_later.perform_now
        expect(Arj::Test::Job.total_executions).to eq(1)
        Arj::Test::Job.perform_later.perform_now
        expect(Arj::Test::Job.total_executions).to eq(2)
      end
    end
  end
end
