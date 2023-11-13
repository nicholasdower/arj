# frozen_string_literal: true

require 'English'
require_relative '../../spec_helper'

describe Arj::Extensions::LastError do
  before do
    stub_const('Arj::LastErrorJob', Class.new(ActiveJob::Base))
    Arj::LastErrorJob.class_eval do
      include Arj
      include Arj::Extensions::LastError
      retry_on Exception

      def perform
        raise 'oh, hi'
      end
    end
  end

  context 'when last_error added to jobs table' do
    before { TestDb.migrate(AddLastErrorToJobs, :up) }

    after do
      Job.destroy_all
      TestDb.migrate(AddLastErrorToJobs, :down)
    end

    context 'serialization' do
      context 'when a job fails' do
        subject { job.perform_now }

        let(:job) { Arj::LastErrorJob.perform_later }

        it 'persists the last error' do
          subject
          expect(Job.last.last_error).to match(/RuntimeError: oh, hi/)
        end
      end

      context 'when error is updated' do
        subject { Arj.update!(job, last_error: error) }

        let!(:job) { Arj::LastErrorJob.perform_later }
        let(:error) do
          raise 'oh, hi'
        rescue RuntimeError => e
          return e
        end

        it 'persists the last error' do
          expect { subject }.to change { Job.sole.last_error }.from(nil).to(/RuntimeError: oh, hi/)
        end

        context 'when error is too long' do
          let(:error) do
            super().tap do |e|
              e.backtrace.clear
              1_000.times { e.backtrace << '0123456789' }
            end
          end

          it 'persists the last error truncated' do
            subject
            expect(Job.sole.last_error).to end_with('… (truncated)')
          end
        end

        context 'when error is not a String or Exception' do
          let(:error) { Object.new }

          it 'raises' do
            expect { subject }.to raise_error('invalid error: Object')
          end
        end

        context 'when error is nil' do
          let(:error) { nil }

          it 'persists the last error' do
            subject
            expect(Job.sole.last_error).to be_nil
          end
        end
      end
    end

    context 'deserialization' do
      subject { Arj.last }

      context 'when a job class with last_error is retrieved' do
        before { Arj::LastErrorJob.perform_now }

        it 'sets the last_error from the database' do
          expect(subject.last_error).to match(/RuntimeError: oh, hi/)
        end
      end

      context 'when a job class without a last_error is retrieved' do
        subject { Arj::Test::Job.set(queue: 'some queue').perform_later }

        it 'successfully reads job data from the database' do
          expect(subject.queue_name).to eq('some queue')
        end
      end
    end

    context '#pretty_print' do
      subject { PP.pp(Arj.last, StringIO.new).string }

      before { Arj::LastErrorJob.perform_now }

      context 'when error has a backtrace' do
        context 'when message is not too long' do
          it 'returns the full message with hidden backtrace' do
            expect(subject).to match(/@last_error="RuntimeError: oh, hi \(backtrace hidden\)",/)
          end
        end

        context 'when message is too long' do
          before do
            job = Arj.last
            job.last_error = raise 100.times.map { |i| i }.join(',').to_s rescue $ERROR_INFO
            job.enqueue
          end

          it 'returns a truncated message with a truncated message' do
            expected = '"RuntimeError: 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,' \
                       '23,24,25,26,27,28,29,30,31,32,33,34,35,3… (backtrace hidden)",'
            expect(subject).to include(expected)
          end
        end
      end

      context 'when error does not have a backtrace' do
        context 'when message is not too long' do
          before do
            job = Arj.last
            job.last_error = RuntimeError.new('oh, hi')
            job.enqueue
          end

          it 'returns the full message without hidden backtrace' do
            expect(subject).to match(/@last_error="RuntimeError: oh, hi",/)
          end
        end

        context 'when message is too long' do
          before do
            job = Arj.last
            job.last_error = RuntimeError.new(100.times.map { |i| i }.join(','))
            job.enqueue
          end

          it 'returns a truncated message with a truncated message' do
            expected = '"RuntimeError: 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,' \
                       '23,24,25,26,27,28,29,30,31,32,33,34,35,3…",'
            expect(subject).to include(expected)
          end
        end
      end
    end
  end

  context 'when last_error not added to jobs table' do
    context '#serialize' do
      subject { Arj::LastErrorJob.perform_later.serialize }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'Job class missing last_error attribute')
      end
    end
  end
end
