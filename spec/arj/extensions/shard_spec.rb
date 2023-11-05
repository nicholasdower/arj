# frozen_string_literal: true

require_relative '../../spec_helper'

describe Arj::Extensions::Shard do
  before do
    TestDb.migrate(AddShardToJobs, :up)
    stub_const('Arj::JobWithShard', Class.new(ActiveJob::Base))
    Arj::JobWithShard.include(Arj::Extensions::Shard)
  end

  after { TestDb.migrate(AddShardToJobs, :down) }

  context 'serialization' do
    context 'when shard is set during creation' do
      subject { Arj::JobWithShard.set(shard: 'some shard').perform_later }

      it 'persists shard to the database' do
        subject
        expect(Job.first.shard).to eq('some shard')
      end
    end

    context 'when shard is updated creation' do
      subject { Arj.update!(job, shard: 'other shard') }

      let(:job) { Arj::JobWithShard.set(shard: 'some shard').perform_later }

      it 'update shard in the database' do
        subject
        expect(Job.first.shard).to eq('other shard')
      end

      it "updates the job's shard" do
        subject
        expect(job.shard).to eq('other shard')
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
    subject { Arj.last }

    context 'when a job class with a shard is retrieved' do
      before { Arj::JobWithShard.set(shard: 'some shard').perform_later }

      it 'sets the shard from the database' do
        expect(subject.shard).to eq('some shard')
      end
    end

    context 'when a job class without a shard is retrieved' do
      subject { Arj::Test::Job.set(queue: 'some queue').perform_later }

      it 'successfully reads job data from the database' do
        expect(subject.queue_name).to eq('some queue')
      end
    end
  end
end
