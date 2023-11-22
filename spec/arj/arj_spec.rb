# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj do
  after { Arj.record_class = 'Job' }

  context '.record_class' do
    subject { Arj.record_class }

    context 'when default' do
      it 'returns default class' do
        expect(subject).to eq(Job)
      end
    end

    context 'when set to invalid class name' do
      let(:arg) { 'FooBarBaz' }

      before { Arj.record_class = 'FooBarBaz' }

      it 'raises' do
        expect { subject }.to raise_error(NameError, 'uninitialized constant FooBarBaz')
      end
    end
  end

  context '.record_class=' do
    subject { Arj.record_class = arg }

    context 'when nil' do
      let(:arg) { nil }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'invalid class: nil')
      end
    end

    context 'when invalid class name' do
      let(:arg) { 'FooBarBaz' }

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when not a String or Class' do
      let(:arg) { 1 }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'invalid class: 1')
      end
    end

    context 'when valid class name' do
      let(:arg) { 'FooBarBaz' }

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end
    end
  end

  context '.from' do
    subject { Arj.from(record, job) }

    let(:job) { Arj.sole }
    let(:record) { Job.sole }

    before { Arj::Test::Job.perform_later('some arg') }

    it 'returns the job' do
      expect(subject).to be_a(Arj::Test::Job)
    end

    context 'when record_class has an ID' do
      let(:record_id) { 1 }

      before do
        stub_const('Arj::IdJob', Class.new(ActiveJob::Base))
        Arj::IdJob.include(Arj)
        Arj::IdJob.include(Arj::Extensions::Id)
        Job.destroy_all
        TestDb.migrate(AddIdToJobs, :up)
        Arj::IdJob.perform_later
      end

      after do
        Job.destroy_all
        TestDb.migrate(AddIdToJobs, :down)

        # Clean up some left over ActiveRecord state that causes warnings.
        Job.aliases_by_attribute_name.delete('id')
      end

      context 'when job attributes have not been populated' do
        let(:job) { Arj::IdJob.new }

        it 'populates provider_job_id' do
          expect { subject }.to change { job.provider_job_id }.from(nil).to(record_id)
        end

        context 'when provider_job_id nil' do
          before { job.provider_job_id = nil }

          it 'does not raise' do
            expect { subject }.not_to raise_error
          end
        end
      end

      context 'when provider_job_id and record ID do not match' do
        before { job.provider_job_id = -1 }

        it 'raises' do
          expect { subject }.to raise_error(StandardError, /unexpected id for/)
        end
      end
    end

    context 'when record_class does not have an ID' do
      context 'when job has provider_job_id' do
        before do
          job.provider_job_id = -1
        end

        it 'raises' do
          expect { subject }.to raise_error(StandardError, /unexpected id for/)
        end
      end
    end

    context 'when record is not of type Arj.record_class' do
      let(:record) { nil }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, /expected Job, found NilClass/)
      end
    end

    context 'when job is not of type record.job_class' do
      let(:job) { Object.new }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, /expected Arj::Test::Job, found Object/)
      end
    end

    context 'when job is nil' do
      let(:job) { nil }

      context 'when job_class is not an ActiveJob::Base' do
        before { record.job_class = 'String' }

        it 'raises' do
          expect { subject }.to raise_error(StandardError, /expected ActiveJob::Base, found String/)
        end
      end

      it 'returns a the job' do
        expect(subject.job_id).to eq(record.job_id)
      end
    end

    context 'when successfully_enqueued is false' do
      before { job.successfully_enqueued = false }

      it 'sets successfully_enqueued?' do
        expect { subject }.to change(job, :successfully_enqueued?).from(false).to(true)
      end
    end

    context 'when job attributes have not been populated' do
      let(:job) { Arj::Test::Job.new }

      it 'populates job fields' do
        expect { subject }.to change { job.job_id }.to(record.job_id)
      end

      it 'populates arguments' do
        expect(job.arguments).to eq([])
        subject
        expect(job.arguments).to eq(['some arg'])
      end
    end
  end

  context '.enqueue' do
    subject { Arj.enqueue(job, timestamp) }

    let(:timestamp) { nil }

    context 'when the job has not been enqueued before' do
      let!(:job) { Arj::Test::Job.new('some arg') }

      it 'finds enqueued_at is nil' do
        expect(job.enqueued_at).to be_nil
      end

      it 'persists the record' do
        expect { subject }.to change(Job, :count).from(0).to(1)
        expect(Job.last.job_id).to eq(job.job_id)
      end

      it 'updates successfully_enqueued' do
        expect { subject }.to change { job.successfully_enqueued? }.from(nil).to(true)
      end
    end

    context 'when the job has been enqueued before' do
      let!(:job) { Arj::Test::Job.perform_later('some arg') }

      it 'updates enqueued_at' do
        Timecop.travel(1.second)
        expect { subject }.to change { Job.sole.enqueued_at.to_s }.from(1.second.ago.to_s).to(Time.now.utc.to_s)
      end

      context 'when the job has been updated' do
        let!(:job) { Arj::Test::Job.set(queue: 'some queue').perform_later('some arg') }

        before { job.queue_name = 'other queue' }

        it 'updates the database' do
          expect { subject }.to change { Job.sole.queue_name }.from('some queue').to('other queue')
        end
      end
    end
  end

  context '.job_data' do
    subject { Arj.send(:job_data, record) }

    let!(:job) { Arj::Test::Job.perform_later(1) }
    let(:record) { Job.sole }

    context 'when arguments is not valid JSON' do
      before do
        record.update!(arguments: '{')
      end

      it 'raises' do
        expect { subject }.to raise_error(JSON::ParserError, "unexpected token at '{'")
      end
    end

    context 'when exception_executions not valid JSON' do
      before do
        record.update!(exception_executions: '{')
      end

      it 'raises' do
        expect { subject }.to raise_error(JSON::ParserError, "unexpected token at '{'")
      end
    end

    context 'when scheduled_at is nil' do
      before do
        record.update!(scheduled_at: nil)
      end

      it 'returns nil scheduled_at' do
        expect(subject['scheduled_at']).to be_nil
      end
    end

    context 'when record missing expected attributes' do
      before do
        stub_const('AddScheduledAtToJobs', Class.new(ActiveRecord::Migration[7.1]))
        AddScheduledAtToJobs.class_eval do
          def self.up
            add_column :jobs, :scheduled_at, :datetime
          end

          def self.down
            remove_column :jobs, :scheduled_at
          end
        end
      end

      after do
        Job.destroy_all
        TestDb.migrate(AddScheduledAtToJobs, :up)
      end

      it 'raises' do
        TestDb.migrate(AddScheduledAtToJobs, :down)
        expect { subject }.to raise_error(KeyError, 'key not found: "scheduled_at"')
      end
    end
  end

  context '.record_attributes' do
    subject { Arj.send(:record_attributes, job) }

    let!(:job) { Arj::Test::Job.perform_later }

    it 'returns expected attributes' do
      expect(subject.keys).to eq(%i[
                                   job_class job_id queue_name priority arguments executions
                                   exception_executions locale timezone enqueued_at scheduled_at
                                 ])
    end

    context 'when locale explicitly set' do
      before { job.locale = 'de' }

      it 'returns the expected locale' do
        expect(subject[:locale]).to eq('de')
      end
    end

    context 'when locale not set' do
      before { job.locale = nil }

      it 'returns the default locale' do
        expect(subject[:locale]).to eq('en')
      end
    end

    context 'when the job is missing a required attribute' do
      before do
        serialized = job.serialize
        serialized.delete('arguments')
        allow(job).to receive(:serialize).and_return(serialized)
      end

      it 'raises' do
        expect { subject }.to raise_error(KeyError, 'key not found: "arguments"')
      end
    end
  end

  context '#method' do
    subject { Arj.method(method_name) }

    context 'when method exists on the record class' do
      let(:method_name) { :first }

      it 'returns the method' do
        expect(subject).to be_a(Method)
        expect(subject.name).to eq(method_name)
      end
    end

    context 'when method exists on the Arj class' do
      let(:method_name) { :to_s }

      it 'returns the method' do
        expect(subject).to be_a(Method)
        expect(subject.name).to eq(method_name)
      end
    end

    context 'when method does not exist' do
      let(:method_name) { :foo }

      it 'raises' do
        expect { subject }.to raise_error(NameError, /undefined method `foo' for class `#<Class:Arj>'/)
      end
    end
  end

  include_examples 'persistence methods', Arj
end
