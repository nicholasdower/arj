# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj::Record do
  context 'Arj.failing' do
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

  context 'Arj.queue' do
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

  context 'Arj.executable' do
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

  context 'Arj.todo' do
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

  context '#to_arj' do
    subject { record.to_arj }

    let(:record) { Job.first }

    before { Arj::Test::Job.set(queue: 'some queue').perform_later }

    it 'returns a job' do
      expect(subject).to be_a(ActiveJob::Base)
      expect(subject.queue_name).to eq('some queue')
    end
  end
end
