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
          before { Job.update!(job.provider_job_id, queue_name: 'some queue') }

          it 'returns the updated job' do
            expect(subject.queue_name).to eq('some queue')
          end
        end

        context 'when the database record never existed' do
          let!(:job) { Arj::Test::Job.new }

          it 'raises' do
            expect { subject }.to raise_error(StandardError, 'record not set')
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

        context 'when the database record never existed' do
          let!(:job) { Arj::Test::Job.new }

          it 'raises' do
            expect { subject }.to raise_error(StandardError, 'record not set')
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

        context 'when the database record never existed' do
          let!(:job) { Arj::Test::Job.new }

          it 'raises' do
            expect { subject }.to raise_error(StandardError, 'record not set')
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
            expect { subject }.to change { Job.exists?(job.provider_job_id) }.from(true).to(false)
          end

          it 'sets successfully_enqueued to false' do
            expect { subject }.to change(job, :successfully_enqueued?).from(true).to(false)
          end
        end

        context 'when the database record never existed' do
          let!(:job) { Arj::Test::Job.new }

          it 'raises' do
            expect { subject }.to raise_error(StandardError, 'record not set')
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

        context 'when the database record never existed' do
          let!(:job) { Arj::Test::Job.new }

          it 'raises' do
            expect { subject }.to raise_error(StandardError, 'record not set')
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

    let(:job) { Arj.first }
    let(:record) { Job.first }

    before { Arj::Test::Job.perform_later('some arg') }

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
      context 'when job_class is not an ActiveJob::Base' do
        let(:job) { nil }

        before { record.job_class = 'String' }

        it 'raises' do
          expect { subject }.to raise_error(StandardError, /expected ActiveJob::Base, found String/)
        end
      end
    end

    context 'when provider_job_id and record ID do not match' do
      before { job.provider_job_id = -1 }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, /unexpected id for/)
      end
    end

    context 'when successfully_enqueued is false' do
      before { job.successfully_enqueued = false }

      it 'sets successfully_enqueued?' do
        expect { subject }.to change(job, :successfully_enqueued?).from(false).to(true)
      end
    end

    context 'record data' do
      let(:job) { Arj::Test::Job.new }

      it 'populates job fields' do
        expect(job.provider_job_id).to be_nil
        subject
        expect(job.provider_job_id).to eq(record.id)
      end

      it 'populates arguments' do
        expect(job.arguments).to eq([])
        subject
        expect(job.arguments).to eq(['some arg'])
      end
    end

    it 'returns the job' do
      expect(subject).to be_a(Arj::Test::Job)
    end
  end
end
