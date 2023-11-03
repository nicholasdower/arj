# frozen_string_literal: true

require_relative 'spec_helper'

describe 'enqueueing' do
  context '.perform_later' do
    subject { Arj::TestJob.set(set_options).perform_later(*args, **kwargs) }

    let(:set_options) { {} }
    let(:args) { [] }
    let(:kwargs) { {} }

    it 'persists a job' do
      expect { subject }.to change(Job, :count).from(0).to(1)
    end

    context 'return value' do
      include_examples 'job fields', Arj::TestJob
    end
  end

  context '.enqueue' do
    subject { Arj.last.enqueue(options) }

    let(:options) { {} }

    before { Arj::TestJob.perform_later }

    context 'when wait specified' do
      let(:options) { { wait: 1.hour } }

      it 'updates scheduled_at' do
        expect { subject }.to change { Arj.last.scheduled_at&.to_s }.from(nil).to(1.hour.from_now.to_s)
      end
    end

    context 'when wait_until specified' do
      let(:options) { { wait_until: 1.hour.from_now } }

      it 'updates scheduled_at' do
        expect { subject }.to change { Arj.last.scheduled_at&.to_s }.from(nil).to(1.hour.from_now.to_s)
      end
    end

    context 'when queue specified' do
      let(:options) { { queue: 'some_queue' } }

      it 'updates queue' do
        expect { subject }.to change { Arj.last.queue_name }.from('default').to('some_queue')
      end
    end

    context 'when priority specified' do
      let(:options) { { priority: 10 } }

      it 'updates priority' do
        expect { subject }.to change { Arj.last.priority }.from(nil).to(10)
      end
    end
  end

  context '.perform_all_later' do
    subject { ActiveJob.perform_all_later(*jobs) }

    let(:jobs) { [Arj::TestJob.new('one'), Arj::TestJob.new('two')] }

    it 'persists all jobs' do
      expect { subject }.to change(Job, :count).from(0).to(2)
      expect(Arj.first.arguments.first).to eq('one')
      expect(Arj.second.arguments.first).to eq('two')
    end
  end
end