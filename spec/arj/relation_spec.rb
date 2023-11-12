# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj::Relation do
  let(:relation) { Arj.all }

  context '#method' do
    subject { relation.method(method_name) }

    context 'when method exists' do
      let(:method_name) { :pluck }

      it 'returns the method' do
        expect(subject).to be_a(Method)
        expect(subject.name).to eq(method_name)
      end
    end

    context 'when method does not exist' do
      let(:method_name) { :foo }

      it 'raises' do
        expect { subject }.to raise_error(NameError, /undefined method `foo' for class `Arj::Relation'/)
      end
    end
  end

  context '#update_job!' do
    subject { relation.update_job!(attributes) }

    let(:attributes) { {} }

    context 'when no records found' do
      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when records found' do
      before do
        Arj::Test::Job.set(priority: 1).perform_later
        Arj::Test::Job.set(priority: 2).perform_later
      end

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
        let(:attributes) { { priority: 9 } }

        it 'updates the database records' do
          expect { subject }.to change { Job.pluck(:priority) }.from([1, 2]).to([9, 9])
        end

        it 'returns the jobs' do
          expect(subject.map(&:job_id)).to contain_exactly(Job.first.job_id, Job.second.job_id)
        end
      end

      context 'when attributes contains multiple known attribute' do
        let(:attributes) { { priority: 9, queue_name: 'queue' } }

        it 'updates the database record' do
          expect(Job.pluck(:priority)).to eq([1, 2])
          expect(Job.pluck(:queue_name)).to eq(%w[default default])
          subject
          expect(Job.pluck(:priority)).to eq([9, 9])
          expect(Job.pluck(:queue_name)).to eq(%w[queue queue])
        end

        it 'returns the jobs' do
          expect(subject.map(&:job_id)).to contain_exactly(Job.first.job_id, Job.second.job_id)
        end
      end

      context 'when not all attributes loaded' do
        let(:relation) { Arj.select(:job_class) }

        it 'raises' do
          expect { subject }.to raise_error(StandardError, 'unexpected job: Job')
        end
      end
    end
  end

  context '#pretty_print' do
    subject { PP.pp(Arj.last, StringIO.new).string }

    before { Arj::Test::Job.perform_later(1) }

    it 'returns Arj jobs representations' do
      expect(subject).to start_with('#<Arj::Test::Job:')
    end
  end

  context '#map' do
    context 'without a block' do
      subject { Arj.all.map }

      before do
        Arj::Test::Job.set(priority: 1).perform_later
        Timecop.travel(1.second)
        Arj::Test::Job.set(priority: 2).perform_later
      end

      it 'returns an Enumerable' do
        expect(subject).to be_a(Enumerable)
      end

      it 'returns an Enumerable of jobs' do
        expect(subject.to_a.map(&:class)).to eq([Arj::Test::Job, Arj::Test::Job])
      end
    end

    context 'with a block' do
      subject { Arj.all.map(&:class) }

      before do
        Arj::Test::Job.set(priority: 1).perform_later
        Timecop.travel(1.second)
        Arj::Test::Job.set(priority: 2).perform_later
      end

      it 'yields to the block and returns the results' do
        expect(subject).to eq([Arj::Test::Job, Arj::Test::Job])
      end

      it 'returns an Array' do
        expect(subject).to be_a(Array)
      end
    end
  end

  context '#each' do
    context 'without a block' do
      subject { Arj.all.each }

      before do
        Arj::Test::Job.set(priority: 1).perform_later
        Timecop.travel(1.second)
        Arj::Test::Job.set(priority: 2).perform_later
      end

      it 'returns an Enumerable' do
        expect(subject).to be_a(Enumerable)
      end

      it 'returns an Enumerable of jobs' do
        expect(subject.to_a.map(&:class)).to eq([Arj::Test::Job, Arj::Test::Job])
      end
    end

    context 'with a block' do
      subject { Arj.all.each { |j| yielded << j.class } }

      let(:yielded) { [] }

      before do
        Arj::Test::Job.set(priority: 1).perform_later
        Timecop.travel(1.second)
        Arj::Test::Job.set(priority: 2).perform_later
      end

      it 'yields to the block' do
        subject
        expect(yielded).to eq([Arj::Test::Job, Arj::Test::Job])
      end

      it 'returns an Array' do
        expect(subject).to be_a(Array)
      end

      it 'returns an Array of jobs' do
        expect(subject.to_a.map(&:class)).to eq([Arj::Test::Job, Arj::Test::Job])
      end
    end
  end

  context '#select' do
    subject { Arj.select(:job_class).sole }

    before { Arj::Test::Job.perform_later }

    context 'when not all attributes loaded' do
      it 'returns records' do
        expect(subject).to be_a(ActiveRecord::Base)
      end
    end
  end

  context '#failing' do
    subject { Arj.failing.to_a }

    context 'when no failing jobs exist' do
      before { Arj::Test::Job.perform_later }

      it 'returns zero jobs' do
        expect(subject.size).to eq(0)
      end
    end

    context 'when failing jobs exist' do
      before do
        Arj::Test::Job.perform_later
        Arj::Test::Job.set(queue: 'some queue').perform_now(Arj::Test::Error)
      end

      it 'returns the failing jobs' do
        expect(subject.map(&:queue_name).sort).to eq(['some queue'])
      end
    end
  end

  context '#queue' do
    subject { Arj.queue(*queues).to_a }

    before do
      Arj::Test::Job.perform_later
      Arj::Test::Job.set(queue: 'ignored queue').perform_later
      Arj::Test::Job.set(queue: 'some queue').perform_later
      Arj::Test::Job.set(queue: 'some queue').perform_later
      Arj::Test::Job.set(queue: 'other queue').perform_later
      Arj::Test::Job.set(queue: 'other queue').perform_later
    end

    context 'when no jobs with specified queue exist' do
      let(:queues) { ['non-existent queue'] }

      before { Arj::Test::Job.perform_later }

      it 'returns zero jobs' do
        expect(subject.size).to eq(0)
      end
    end

    context 'when jobs with the specified queue exist' do
      let(:queues) { ['some queue'] }

      it 'returns the jobs' do
        expect(subject.map(&:queue_name).sort).to eq(['some queue', 'some queue'])
      end
    end

    context 'when jobs with the specified queues exist' do
      let(:queues) { ['some queue', 'other queue'] }

      it 'returns the jobs' do
        expect(subject.map(&:queue_name).sort).to eq(['other queue', 'other queue', 'some queue', 'some queue'])
      end
    end
  end

  context '#executable' do
    subject { Arj.executable.to_a }

    context 'when no ready jobs exist' do
      before { Arj::Test::Job.set(wait: 1.second).perform_later }

      it 'returns zero jobs' do
        expect(subject.size).to eq(0)
      end
    end

    context 'when jobs without a scheduled_at exist' do
      before do
        Arj::Test::Job.set(queue: 'some queue').perform_later
        Arj::Test::Job.set(wait: 1.second).perform_later
      end

      it 'returns the jobs' do
        expect(subject.map(&:queue_name).sort).to eq(['some queue'])
      end
    end

    context 'when jobs with a scheduled_at in the past exist' do
      before do
        Arj::Test::Job.set(queue: 'some queue', wait: 1.second).perform_later
        Timecop.travel(1.second)
        Arj::Test::Job.set(wait: 1.second).perform_later
      end

      it 'returns the jobs' do
        expect(subject.map(&:queue_name).sort).to eq(['some queue'])
      end
    end
  end

  context '#todo' do
    subject { Arj.todo.to_a }

    let(:priorities) { subject.map(&:priority) }
    let(:queues) { subject.map(&:queue_name).map(&:to_i) }

    context 'when no ready jobs exist' do
      before { Arj::Test::Job.set(wait: 1.second).perform_later }

      it 'returns zero jobs' do
        expect(subject.size).to eq(0)
      end
    end

    context 'when jobs without a scheduled_at exist' do
      before do
        Arj::Test::Job.set(priority: 1).perform_later
        Arj::Test::Job.set(priority: 2, wait: 1.second).perform_later
      end

      it 'returns the jobs' do
        expect(priorities).to eq([1])
      end
    end

    context 'when jobs with a scheduled_at in the past exist' do
      before do
        Arj::Test::Job.set(priority: 1, wait: 1.second).perform_later
        Timecop.travel(1.second)
        Arj::Test::Job.set(priority: 2, wait: 1.second).perform_later
      end

      it 'returns the jobs' do
        expect(priorities).to eq([1])
      end
    end

    context 'when priorities differ' do
      context 'when scheduled_at is nil' do
        before do
          Arj::Test::Job.set(priority: 2, queue: 2, wait: nil).perform_later
          Timecop.travel(1.second)
          Arj::Test::Job.set(priority: 1, queue: 2, wait: nil).perform_later
          Timecop.travel(1.second)
        end

        it 'returns the jobs in priority order' do
          expect(priorities).to eq([1, 2])
        end
      end

      context 'when scheduled_at order is different from priority order' do
        before do
          Arj::Test::Job.set(priority: 3, queue: 2, wait: 3.seconds).perform_later
          Arj::Test::Job.set(priority: 2, queue: 2, wait: 2.seconds).perform_later
          Arj::Test::Job.set(priority: 1, queue: 2, wait: nil).perform_later
          Timecop.travel(4.seconds)
        end

        it 'returns the jobs in priority order' do
          expect(priorities).to eq([1, 2, 3])
        end
      end

      context 'when scheduled_at order matches priority order' do
        before do
          Arj::Test::Job.set(priority: 1, queue: 2, wait: 3.seconds).perform_later
          Arj::Test::Job.set(priority: 2, queue: 2, wait: 2.seconds).perform_later
          Arj::Test::Job.set(priority: 3, queue: 2, wait: nil).perform_later
          Timecop.travel(4.seconds)
        end

        it 'returns the jobs in priority order' do
          expect(priorities).to eq([1, 2, 3])
        end
      end
    end

    context 'when priorities are equal' do
      context 'when scheduled_at times are not equal' do
        before do
          Arj::Test::Job.set(priority: 1, queue: 3, wait: nil).perform_later
          Arj::Test::Job.set(priority: 1, queue: 2, wait: 3.seconds).perform_later
          Arj::Test::Job.set(priority: 1, queue: 1, wait: 2.seconds).perform_later
          Timecop.travel(4.seconds)
        end

        it 'returns the jobs in scheduled_at order, nulls last' do
          expect(queues).to eq([1, 2, 3])
        end
      end

      context 'when scheduled_at times are equal' do
        context 'when enqueued_at times are not equal' do
          before do
            Arj::Test::Job.set(priority: 1, queue: 1, wait: 3.seconds).perform_later
            Timecop.travel(1.second)
            Arj::Test::Job.set(priority: 1, queue: 2, wait: 3.seconds).perform_later
            Timecop.travel(1.second)
            Arj::Test::Job.set(priority: 1, queue: 3, wait: nil).perform_later
            Timecop.travel(1.second)
            Arj::Test::Job.set(priority: 1, queue: 4, wait: nil).perform_later
            Timecop.travel(1.second)
          end

          it 'returns the jobs in enqueued order' do
            expect(queues).to eq([1, 2, 3, 4])
          end
        end
      end
    end
  end
end
