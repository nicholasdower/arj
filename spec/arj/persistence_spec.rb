# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj::Persistence do
  [
    [Arj, true],
    [Arj::Query, false]
  ].each do |target_class, class_methods|
    context "#{target_class} methods" do
      let(:description) { class_methods ? "#{target_class}." : "#{target_class}#" }

      context "#{description}exists?" do
        subject { class_methods ? Arj.exists?(job) : job.exists? }

        let!(:job) { Arj::Test::Job.perform_later }

        context 'when the database record exists' do
          it 'returns true' do
            expect(subject).to eq(true)
          end
        end

        context 'when the database record never existed' do
          let!(:job) { Arj::Test::Job.new }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end

        context 'when the database record has been deleted' do
          before { Job.destroy_all }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end

      context "#{description}reload" do
        subject { class_methods ? Arj.reload(job) : job.reload }

        let!(:job) { Arj::Test::Job.perform_later }

        context 'when the database record has been updated' do
          before { Job.update!(job.job_id, queue_name: 'some queue') }

          it 'returns the updated job' do
            expect(subject.queue_name).to eq('some queue')
          end
        end

        context 'when the database record has been deleted' do
          before { Job.destroy_all }

          it 'raises' do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end

      context "#{description}save!" do
        subject { class_methods ? Arj.save!(job) : job.save! }

        let!(:job) { Arj::Test::Job.perform_later }

        context 'when the job has been updated' do
          before { job.queue_name = 'some queue' }

          it 'updates the database' do
            expect { subject }.to change { Job.sole.queue_name }.from('default').to('some queue')
          end

          it 'returns true' do
            expect(subject).to eq(true)
          end
        end

        context 'when the database record has been deleted' do
          before { Job.destroy_all }

          it 'raises' do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end

      context "#{description}update!" do
        subject { class_methods ? Arj.update!(job, attributes) : job.update!(attributes) }

        let!(:job) { Arj::Test::Job.perform_later }
        let(:attributes) { {} }

        context 'when attributes is not a hash' do
          let(:attributes) { nil }

          it 'raises' do
            expect { subject }.to raise_error(StandardError, /invalid attributes/)
          end
        end

        context 'when attributes contains unknown attributes' do
          let(:attributes) { { foo: 1 } }

          it 'raises' do
            expect { subject }.to raise_error(NoMethodError, /undefined method `foo=/)
          end
        end

        context 'when attributes contains a single known attribute' do
          let(:attributes) { { queue_name: 'some queue' } }

          it 'updates the job' do
            expect { subject }.to change(job, :queue_name).from('default').to('some queue')
          end

          it 'updates the database record' do
            expect { subject }.to change { Job.sole.queue_name }.from('default').to('some queue')
          end

          it 'returns true' do
            expect(subject).to eq(true)
          end
        end

        context 'when attributes contains multiple known attribute' do
          let(:attributes) { { queue_name: 'some queue', executions: 1 } }

          it 'updates the job' do
            expect(job.executions).to eq(0)
            expect(job.queue_name).to eq('default')
            subject
            expect(job.executions).to eq(1)
            expect(job.queue_name).to eq('some queue')
          end

          it 'updates the database' do
            expect(Job.sole.executions).to eq(0)
            expect(Job.sole.queue_name).to eq('default')
            subject
            expect(Job.sole.executions).to eq(1)
            expect(Job.sole.queue_name).to eq('some queue')
          end

          it 'returns true' do
            expect(subject).to eq(true)
          end
        end

        context 'when the database record has been deleted' do
          before { Job.destroy_all }

          it 'raises' do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end

      context "#{description}destroy!" do
        subject { class_methods ? Arj.destroy!(job) : job.destroy! }

        let!(:job) { Arj::Test::Job.perform_later }

        context 'when the database record exists' do
          it 'deletes the record' do
            expect { subject }.to change { Job.exists?(job.job_id) }.from(true).to(false)
          end

          it 'sets successfully_enqueued to false' do
            expect { subject }.to change(job, :successfully_enqueued?).from(true).to(false)
          end
        end

        context 'when the database record has been deleted' do
          before { Job.destroy_all }

          it 'raises' do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end

      context "#{description}destroyed?" do
        subject { class_methods ? Arj.destroyed?(job) : job.destroyed? }

        let!(:job) { Arj::Test::Job.perform_later }

        context 'when the database record exists' do
          it 'returns false' do
            expect(subject).to eq(false)
          end
        end

        context 'when the database record has been deleted' do
          before { Job.destroy_all }

          it 'returns true' do
            expect(subject).to eq(true)
          end
        end
      end
    end
  end

  context '.from_record' do
    subject { Arj::Persistence.from_record(record, job) }

    let(:job) { Arj.sole }
    let(:record) { Job.sole }

    before { Arj::Test::Job.perform_later('some arg') }

    it 'returns the job' do
      expect(subject).to be_a(Arj::Test::Job)
    end

    context 'when record_class has an ID' do
      let(:record_id) { 1 }

      before do
        TestDb.migrate(CreateJobs, :down)
        TestDb.migrate(CreateJobsWithId, :up)
        Arj::Test::Job.perform_later
      end

      after do
        TestDb.migrate(CreateJobsWithId, :down)
        TestDb.migrate(CreateJobs, :up)

        # Clean up some left over ActiveRecord state that causes warnings.
        Job.aliases_by_attribute_name.delete('id')
      end

      context 'when job attributes have not been populated' do
        let(:job) { Arj::Test::Job.new }

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

      context 'when provider_job_id nil' do
        before { job.provider_job_id = nil }

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

    context 'when job_ids do not match' do
      before { job.job_id = 'other job id' }

      it 'raises' do
        expect { subject }.to raise_error(ArgumentError, /unexpected job_id for/)
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

      it 'returns an enhanced job' do
        expect(subject.singleton_class.instance_variable_get(:@__arj)).to eq(true)
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

      it 'enhances the job with Arj features' do
        expect { subject }.to change { job.singleton_class.instance_variable_get(:@__arj) }.from(nil).to(true)
      end
    end
  end

  context '.enqueue' do
    subject { Arj::Persistence.enqueue(job, timestamp) }

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

      it 'enhances the job with Arj features' do
        expect { subject }.to change { job.singleton_class.instance_variable_get(:@__arj) }.from(nil).to(true)
      end
    end

    context 'when the job has been enqueued before' do
      let!(:job) { Arj::Test::Job.perform_later('some arg') }

      it 'updates enqueued_at' do
        Timecop.travel(1.second)
        expect { subject }.to change { Job.sole.enqueued_at.to_s }.from(1.second.ago.to_s).to(Time.zone.now.to_s)
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
    subject { Arj::Persistence.job_data(record) }

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
        stub_const('AddEnqueuedAtToJobs', Class.new(ActiveRecord::Migration[7.1]))
        AddEnqueuedAtToJobs.class_eval do
          def self.up
            add_column :jobs, :enqueued_at, :datetime, null: false
          end

          def self.down
            remove_column :jobs, :enqueued_at
          end
        end
      end

      after do
        Job.destroy_all
        TestDb.migrate(AddEnqueuedAtToJobs, :up)
      end

      it 'raises' do
        TestDb.migrate(AddEnqueuedAtToJobs, :down)
        expect { subject }.to raise_error(KeyError, 'key not found: "enqueued_at"')
      end
    end
  end

  context '.record_attributes' do
    subject { Arj::Persistence.record_attributes(job) }

    let!(:job) { Arj::Test::Job.perform_later }

    it 'returns expected attributes' do
      expect(subject.keys).to eq(%i[
                                   job_class job_id queue_name priority arguments executions
                                   exception_executions locale timezone enqueued_at scheduled_at
                                 ])
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
end
