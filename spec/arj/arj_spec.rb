# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj do
  after { Arj.record_class = 'Job' }

  context '.record_class' do
    subject { Arj.record_class }

    context 'when default' do
      it 'returns default class' do
        expect(subject).to eq(Job)
      end
    end

    context 'when set to invalid class name' do
      let(:arg) { 'FooBarBaz' }

      before { Arj.record_class = 'FooBarBaz' }

      it 'raises' do
        expect { subject }.to raise_error(NameError, 'uninitialized constant FooBarBaz')
      end
    end
  end

  context '.record_class=' do
    subject { Arj.record_class = arg }

    context 'when nil' do
      let(:arg) { nil }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'invalid class: nil')
      end
    end

    context 'when invalid class name' do
      let(:arg) { 'FooBarBaz' }

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when not a String or Class' do
      let(:arg) { 1 }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'invalid class: 1')
      end
    end

    context 'when valid class name' do
      let(:arg) { 'FooBarBaz' }

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
