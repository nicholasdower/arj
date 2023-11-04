# frozen_string_literal: true

require_relative 'spec_helper'

describe Arj do
  context '.record_class=' do
    subject { Arj.record_class = arg }

    context 'when nil' do
      let(:arg) { nil }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'invalid class: nil')
      end
    end
  end
end
