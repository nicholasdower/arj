# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj::Migration do
  context '.[]' do
    subject { described_class[version] }

    context 'when version supported' do
      let(:version) { 7.1 }

      it 'returns the corresponding migration class' do
        expect(subject).to eq(Arj::Migration::V7_1)
      end
    end

    context 'when version unsupported' do
      let(:version) { 7.2 }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'Unsupported version: 7.2')
      end
    end
  end
end
