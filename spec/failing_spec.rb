# frozen_string_literal: true

require_relative 'spec_helper'

describe 'failing' do
  context 'when non-enqueued job raises' do
    context '#perform_now' do
      subject { job.perform_now }

      let(:job) { Arj::Test::Job.new(StandardError, 'error') }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'error')
      end

      it 'does not persist the job' do
        expect { subject rescue nil }.not_to change(Job, :count).from(0)
      end
    end

    context '.perform_now with non-retryable error' do
      context 'when error is not retryable' do
        subject { Arj::Test::Job.perform_now(StandardError, 'error') }

        it 'raises' do
          expect { subject }.to raise_error(StandardError, 'error')
        end

        it 'does not persist the job' do
          expect { subject rescue nil }.not_to change(Job, :count).from(0)
        end
      end

      context 'when error is retryable' do
        subject { Arj::Test::Job.perform_now(Arj::Test::Error, 'error') }

        it 'does not raise' do
          expect { subject }.not_to raise_error
        end

        it 'returns the error' do
          expect(subject).to be_a(Arj::Test::Error)
          expect(subject.message).to eq('error')
        end

        it 'persists the job' do
          expect { subject }.to change(Job, :count).from(0).to(1)
        end
      end
    end
  end

  context 'when enqueued job raises' do
    subject { job.perform_now }

    let(:job) { original_job }
    let(:original_job) { enqueue }
    let(:enqueue) { Arj::Test::Job.perform_later(error, 'error') }

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

      it "clears the original job's enqueued_at" do
        expect { subject rescue nil }.to change { original_job.enqueued_at&.to_s }.from(Time.now.utc.to_s).to(nil)
      end

      it "does not set the original job's exception_executions" do
        expect { subject rescue nil }.not_to change { original_job.exception_executions }.from({})
      end
    end

    context 'with retries' do
      let(:error) { Arj::Test::Error }

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end

      it 'returns the error' do
        expect(subject).to be_a(Arj::Test::Error)
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
          .from(1.minute.ago.to_s).to(Time.now.utc.to_s)
      end

      it "sets the persisted job's enqueued_at" do
        Timecop.travel(1.minute)
        expect { subject rescue nil }.to change { Arj.last.enqueued_at&.to_s }
          .from(1.minute.ago.to_s).to(Time.now.utc.to_s)
      end

      it "sets the original job's scheduled_at" do
        expect { subject rescue nil }.to change { original_job.scheduled_at&.to_s }.from(nil).to(1.minute.from_now.to_s)
      end

      it "sets the persisted job's scheduled_at" do
        expect { subject rescue nil }.to change { Arj.last.scheduled_at&.to_s }.from(nil).to(1.minute.from_now.to_s)
      end

      it "sets the original job's exception_executions" do
        expect { subject rescue nil }.to change { original_job.exception_executions }
          .from({}).to({ '[Arj::Test::Error]' => 1 })
      end

      it "sets the persisted job's exception_executions" do
        expect { subject rescue nil }.to change { Arj.last.exception_executions }
          .from({}).to({ '[Arj::Test::Error]' => 1 })
      end

      context 'when all attempts are exhausted' do
        before { job.perform_now }

        it 'raises' do
          expect { subject }.to raise_error(Arj::Test::Error)
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
