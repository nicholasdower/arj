# frozen_string_literal: true

require 'pp'
require_relative 'spec_helper'

describe 'querying' do
  context 'single job return type' do
    subject { Arj.last }

    let(:set_options) { {} }
    let(:args) { [] }
    let(:kwargs) { {} }

    before { Arj::TestJob.set(set_options).perform_later(*args, **kwargs) }

    include_examples 'job fields', Arj::TestJob
  end

  context '.all' do
    context 'when no jobs enqueued' do
      subject { Arj.all }

      it 'returns zero jobs' do
        expect(subject.to_a.size).to eq(0)
      end
    end

    context 'when one job enqueued' do
      subject { Arj.all }

      before { Arj::TestJob.set(queue: 'one').perform_later(1) }

      it 'returns the job' do
        expect(subject.to_a.size).to eq(1)
        expect(subject.to_a.first.queue_name).to eq('one')
      end
    end

    context 'when multiple jobs enqueued' do
      subject { Arj.all }

      before do
        Arj::TestJob.set(queue: 'one').perform_later(1)
        Arj::TestJob.set(queue: 'two').perform_later(2)
      end

      it 'returns the jobs' do
        expect(subject.to_a.size).to eq(2)
        expect(subject.to_a.first.queue_name).to eq('one')
        expect(subject.to_a.second.queue_name).to eq('two')
      end
    end
  end

  context '.where' do
    before do
      Arj::TestJob.set(priority: 1, queue: 'one').perform_later(1)
      Arj::TestJob.set(priority: 1, queue: 'two').perform_later(2)
    end

    context 'when no jobs match' do
      subject { Arj.where(queue_name: 'three') }

      it 'returns zero jobs' do
        expect(subject.to_a.size).to eq(0)
      end
    end

    context 'when on job matches' do
      subject { Arj.where(queue_name: 'one') }

      it 'returns the job' do
        expect(subject.to_a.size).to eq(1)
        expect(subject.to_a.first.queue_name).to eq('one')
      end
    end

    context 'when multiple jobs enqueued' do
      subject { Arj.where(priority: 1) }

      before do
        Arj::TestJob.perform_later(1)
        Arj::TestJob.perform_later(2)
      end

      it 'returns the jobs' do
        expect(subject.to_a.size).to eq(2)
        expect(subject.to_a.first.queue_name).to eq('one')
        expect(subject.to_a.second.queue_name).to eq('two')
      end
    end
  end

  context '.where' do
    before do
      Arj::TestJob.set(priority: 1, queue: 'one').perform_later(1)
      Arj::TestJob.set(priority: 1, queue: 'two').perform_later(2)
    end

    context 'when no jobs match' do
      subject { Arj.where(queue_name: 'three') }

      it 'returns zero jobs' do
        expect(subject.to_a.size).to eq(0)
      end
    end

    context 'when on job matches' do
      subject { Arj.where(queue_name: 'one') }

      it 'returns the job' do
        expect(subject.to_a.size).to eq(1)
        expect(subject.to_a.first.queue_name).to eq('one')
      end
    end

    context 'when multiple jobs enqueued' do
      subject { Arj.where(priority: 1) }

      before do
        Arj::TestJob.perform_later(1)
        Arj::TestJob.perform_later(2)
      end

      it 'returns the jobs' do
        expect(subject.to_a.size).to eq(2)
        expect(subject.to_a.first.queue_name).to eq('one')
        expect(subject.to_a.second.queue_name).to eq('two')
      end
    end
  end

  context '.pretty_inspect' do
    before { Arj::TestJob.perform_later(1) }

    subject { Arj.all.pretty_inspect }

    it 'returns Arj jobs representations' do
      expect(subject).to start_with('[#<Arj::TestJob:')
    end
  end
end
