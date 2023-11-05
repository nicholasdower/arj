# frozen_string_literal: true

require_relative 'spec_helper'

describe Arj::Worker do
  let(:worker) { Arj::Worker.new }

  context '#execute_next' do
    it 'blah' do
      expect(1).to eq(1)
    end
  end
end
