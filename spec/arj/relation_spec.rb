# frozen_string_literal: true

require 'pp'
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
end
