# frozen_string_literal: true

shared_examples 'persistence methods' do |target_class|
  let(:description) { target_class == Arj ? "#{target_class}." : "#{target_class}#" }

  context "#{description}exists?" do
    subject { target_class == Arj ? Arj.job_exists?(job) : job.exists? }

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
    subject { target_class == Arj ? Arj.reload_job(job) : job.reload }

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
    subject { target_class == Arj ? Arj.save_job!(job) : job.save! }

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

      it 'recreates the record' do
        expect { subject }.to change(Job, :count).from(0).to(1)
        expect(Job.last.job_id).to eq(job.job_id)
      end
    end
  end

  context "#{description}update!" do
    subject { target_class == Arj ? Arj.update_job!(job, attributes) : job.update!(attributes) }

    let!(:job) { Arj::Test::Job.perform_later(*arguments) }
    let(:arguments) { [] }
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

    context 'when arguments attribute specified' do
      let(:attributes) { { arguments: ['bar'] } }
      let(:arguments) { ['foo'] }

      it 'updates the job' do
        expect { subject }.to change(job, :arguments).from(['foo']).to(['bar'])
      end

      it 'updates the database record' do
        expect { subject }.to change { Job.sole.arguments }.from('["foo"]').to('["bar"]')
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
    subject { target_class == Arj ? Arj.destroy_job!(job) : job.destroy! }

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
    subject { target_class == Arj ? Arj.job_destroyed?(job) : job.destroyed? }

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
