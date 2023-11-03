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
end
