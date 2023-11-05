# frozen_string_literal: true

require_relative 'spec_helper'

describe Arj::Worker do
  let(:worker) { Arj::Worker.new }

  let(:jobs) { [] }

  context '#execute_next' do
    subject { worker.execute_next }

    context 'when no jobs are available' do
      before do
        jobs << Arj::Test::Job.set(wait: 1.second).perform_later
      end

      it 'returns false' do
        expect(subject).to eq(false)
      end

      it 'does not executes other jobs' do
        expect { subject }.not_to change(jobs.first, :global_executions).from(0)
      end

      it 'does not delete other jobs' do
        expect { subject }.not_to change { Job.exists?(jobs.first.provider_job_id) }.from(true)
      end
    end

    context 'when a job is available' do
      before do
        jobs << Arj::Test::Job.perform_later
        Timecop.travel(1.second)
        jobs << Arj::Test::Job.perform_later
      end

      it 'executes the job' do
        expect { subject }.to change(jobs.first, :global_executions).from(0).to(1)
      end

      it 'deletes the job' do
        expect { subject }.to change { Job.exists?(jobs.first.provider_job_id) }.from(true).to(false)
      end

      it 'does not executes other jobs' do
        expect { subject }.not_to change(jobs.second, :global_executions).from(0)
      end

      it 'does not delete other jobs' do
        expect { subject }.not_to change { Job.exists?(jobs.second.provider_job_id) }.from(true)
      end

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end

  context '#work_off' do
    subject { worker.work_off }

    context 'when no jobs are available' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when jobs are available' do
      let(:jobs) { [] }

      before do
        jobs << Arj::Test::Job.perform_later
        Timecop.travel(1.second)
        jobs << Arj::Test::Job.perform_later
        Timecop.travel(1.second)
        jobs << Arj::Test::Job.set(wait: 1.second).perform_later
      end

      it 'executes the jobs' do
        expect(jobs.first.global_executions).to eq(0)
        expect(jobs.second.global_executions).to eq(0)
        subject
        expect(jobs.first.global_executions).to eq(1)
        expect(jobs.second.global_executions).to eq(1)
      end

      it 'deletes the jobs' do
        expect(Job.exists?(jobs.first.provider_job_id)).to eq(true)
        expect(Job.exists?(jobs.second.provider_job_id)).to eq(true)
        subject
        expect(Job.exists?(jobs.first.provider_job_id)).to eq(false)
        expect(Job.exists?(jobs.second.provider_job_id)).to eq(false)
      end

      it 'does not executes other jobs' do
        expect { subject }.not_to change(jobs.third, :global_executions).from(0)
      end

      it 'does not delete other jobs' do
        expect { subject }.not_to change { Job.exists?(jobs.third.provider_job_id) }.from(true)
      end

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end
end
