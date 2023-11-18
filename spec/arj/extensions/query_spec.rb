# frozen_string_literal: true

require 'pp'
require_relative '../../spec_helper'

describe Arj::Extensions::Query do
  context 'Arj.last' do
    subject { Arj.last }

    let(:set_options) { {} }
    let(:args) { [] }
    let(:kwargs) { {} }

    before { Arj::Test::Job.set(set_options).perform_later(*args, **kwargs) }

    include_examples 'job fields', Arj::Test::Job
  end

  context 'Arj.all' do
    context 'when no jobs enqueued' do
      subject { Arj.all }

      it 'returns zero jobs' do
        expect(subject.to_a.size).to eq(0)
      end
    end

    context 'when one job enqueued' do
      subject { Arj.all }

      before { Arj::Test::Job.set(queue: 'one').perform_later(1) }

      it 'returns the job' do
        expect(subject.to_a.size).to eq(1)
        expect(subject.to_a.first.queue_name).to eq('one')
      end
    end

    context 'when multiple jobs enqueued' do
      subject { Arj.all }

      before do
        Arj::Test::Job.set(queue: 'one').perform_later(1)
        Arj::Test::Job.set(queue: 'two').perform_later(2)
      end

      it 'returns the jobs' do
        expect(subject.to_a.size).to eq(2)
        expect(subject.to_a.first.queue_name).to eq('one')
        expect(subject.to_a.second.queue_name).to eq('two')
      end
    end
  end

  context 'Arj.where' do
    before do
      Arj::Test::Job.set(priority: 1, queue: 'one').perform_later(1)
      Arj::Test::Job.set(priority: 1, queue: 'two').perform_later(2)
    end

    context 'when no jobs match' do
      subject { Arj.where(queue_name: 'three') }

      it 'returns zero jobs' do
        expect(subject.to_a.size).to eq(0)
      end
    end

    context 'when one job matches' do
      subject { Arj.where(queue_name: 'one') }

      it 'returns the job' do
        expect(subject.to_a.size).to eq(1)
        expect(subject.to_a.first.queue_name).to eq('one')
      end
    end

    context 'when multiple jobs enqueued' do
      subject { Arj.where(priority: 1) }

      before do
        Arj::Test::Job.perform_later(1)
        Arj::Test::Job.perform_later(2)
      end

      it 'returns the jobs' do
        expect(subject.to_a.size).to eq(2)
        expect(subject.to_a.first.queue_name).to eq('one')
        expect(subject.to_a.second.queue_name).to eq('two')
      end
    end
  end

  context 'Arj.pluck' do
    subject { Arj.pluck(:queue_name) }

    before do
      Arj::Test::Job.set(queue: 'one').perform_later
      Arj::Test::Job.set(queue: 'two').perform_later
    end

    it 'returns the plucked values' do
      expect(subject).to eq(%w[one two])
    end
  end

  context '#pretty_inspect' do
    subject { Arj.all.pretty_inspect }

    before { Arj::Test::Job.perform_later(1) }

    it 'returns Arj jobs representations' do
      expect(subject).to start_with('[#<Arj::Test::Job:')
    end
  end

  context 'class including Query' do
    subject { Arj::SampleJob.all.to_a }

    before do
      stub_const('Arj::SampleJob', Class.new(ActiveJob::Base))
      Arj::SampleJob.include(Arj)
      Arj::SampleJob.include(Arj::Extensions::Query)
      Arj::Test::Job.perform_later('some arg')
      Arj::SampleJob.perform_later('some arg')
    end

    it 'queries for jobs with this class' do
      expect(subject.size).to eq(1)
      expect(subject.first).to be_a(Arj::SampleJob)
    end

    context 'when .all method is overridden' do
      before do
        Arj::SampleJob.class_eval do
          def self.all
            Arj.where(job_class: Arj::Test::Job.name)
          end
        end
      end

      it 'uses the the custom all method' do
        expect(subject.to_a.size).to eq(1)
        expect(subject.first).to be_a(Arj::Test::Job)
      end
    end
  end
end
