# frozen_string_literal: true

require_relative 'spec_helper'

describe 'failing' do
  context 'when non-enqueued job raises' do
    context '#perform_now' do
      subject { job.perform_now }

      let(:job) { Arj::TestJob.new(error: StandardError, message: 'error') }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'error')
      end

      it 'does not persist a job' do
        expect { subject rescue nil }.not_to change(Job, :count).from(0)
      end
    end

    context '.perform_now' do
      subject { Arj::TestJob.perform_now(error: StandardError, message: 'error') }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'error')
      end

      it 'does not persist a job' do
        expect { subject rescue nil }.not_to change(Job, :count).from(0)
      end
    end
  end

  context 'when enqueued job raises' do
    subject { job.perform_now }

    let(:job) { original_job }
    let(:original_job) { enqueue }
    let(:enqueue) { Arj::TestJobWithRetry.perform_later(error:, message: 'error') }

    before { enqueue }

    context 'without retries' do
      let(:error) { StandardError }

      it 'raises' do
        expect { subject }.to raise_error(StandardError)
      end

      it 'deletes the job' do
        expect { subject rescue nil }.to change(Job, :count).from(1).to(0)
      end

      it "increments the original job's executions" do
        expect { subject rescue nil }.to change(original_job, :executions).from(0).to(1)
      end

      it "does not set the original job's scheduled_at" do
        expect { subject rescue nil }.not_to change { original_job.scheduled_at }.from(nil)
      end

      it "does not set the original job's enqueued_at" do
        expect { subject rescue nil }.not_to change { original_job.enqueued_at.to_s }.from(Time.zone.now.to_s)
      end

      it "does not set the original job's exception_executions" do
        expect { subject rescue nil }.not_to change { original_job.exception_executions }.from({})
      end
    end

    context 'with retries' do
      let(:error) { Arj::RetryError }

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end

      it 'returns the error' do
        expect(subject).to be_a(Arj::RetryError)
      end

      it "increments the original job's executions" do
        expect { subject rescue nil }.to change(original_job, :executions).from(0).to(1)
      end

      it "increments the persisted job's executions" do
        expect { subject rescue nil }.to change { Arj.last.executions }.from(0).to(1)
      end

      it "sets the original job's enqueued_at" do
        Timecop.travel(1.minute)
        expect { subject rescue nil }.to change { original_job.enqueued_at&.to_s }
          .from(1.minute.ago.to_s).to(Time.zone.now.to_s)
      end

      it "sets the persisted job's enqueued_at" do
        Timecop.travel(1.minute)
        expect { subject rescue nil }.to change { Arj.last.enqueued_at&.to_s }
          .from(1.minute.ago.to_s).to(Time.zone.now.to_s)
      end

      it "sets the original job's scheduled_at" do
        expect { subject rescue nil }.to change { original_job.scheduled_at&.to_s }.from(nil).to(1.minute.from_now.to_s)
      end

      it "sets the persisted job's scheduled_at" do
        expect { subject rescue nil }.to change { Arj.last.scheduled_at&.to_s }.from(nil).to(1.minute.from_now.to_s)
      end

      it "sets the original job's exception_executions" do
        expect { subject rescue nil }.to change { original_job.exception_executions }
          .from({}).to({ '[Arj::RetryError]' => 1 })
      end

      it "sets the persisted job's exception_executions" do
        expect { subject rescue nil }.to change { Arj.last.exception_executions }
          .from({}).to({ '[Arj::RetryError]' => 1 })
      end

      context 'when all attempts are exhausted' do
        before { job.perform_now }

        it 'raises' do
          expect { subject }.to raise_error(Arj::RetryError)
        end

        it 'deletes the job' do
          expect { subject rescue nil }.to change(Job, :count).from(1).to(0)
        end

        it "increments the original job's executions" do
          expect { subject rescue nil }.to change(original_job, :executions).from(1).to(2)
        end
      end
    end
  end
end