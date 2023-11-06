# frozen_string_literal: true

require_relative '../spec_helper'

describe Arj::Job do
  context '#perform_now' do
    context 'when the job is re-enqueued' do
      let!(:job) { Arj::Test::Job.perform_later(Arj::Test::Error) }

      it 'does not delete the database record' do
        expect { job.perform_now }.not_to change(Job, :count).from(1)
      end
    end

    context 'when the job is not re-enqueued' do
      let!(:job) { Arj::Test::Job.perform_later }

      it 'deletes the database record' do
        expect { job.perform_now }.to change(Job, :count).from(1).to(0)
      end

      context 'when the database record no longer exists' do
        before { Job.destroy_all }

        it 'raises' do
          expect { job.perform_now }.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find Job with 'id'/)
        end
      end
    end
  end
end
