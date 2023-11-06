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
          expect(subject.first.provider_job_id).to eq(Job.first.id)
          expect(subject.second.provider_job_id).to eq(Job.second.id)
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
          expect(subject.first.provider_job_id).to eq(Job.first.id)
          expect(subject.second.provider_job_id).to eq(Job.second.id)
        end
      end
    end
  end

  context '#pretty_inspect' do
    subject { relation.pretty_inspect }

    before { Arj::Test::Job.perform_later(1) }

    it 'returns Arj jobs representations' do
      expect(subject).to start_with('[#<Arj::Test::Job:')
    end
  end
end
