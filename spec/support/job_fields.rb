# frozen_string_literal: true

shared_examples 'job fields' do |expected_clazz|
  it 'is a job instance' do
    expect(subject).to be_a(expected_clazz)
  end

  it 'has job_id' do
    expect(subject.job_id).not_to be_empty
  end

  it 'has provider_job_id' do
    expect(subject.provider_job_id).to eq(Job.last.id)
  end

  context 'when queue not specified' do
    it 'has default queue_name' do
      expect(subject.queue_name).to eq('default')
    end
  end

  context 'when queue specified' do
    let(:set_options) { { queue: 'some_queue' } }

    it 'has queue_name' do
      expect(subject.queue_name).to eq('some_queue')
    end
  end

  context 'when priority not specified' do
    it 'has nil priority' do
      expect(subject.priority).to be_nil
    end
  end

  context 'when priority specified' do
    let(:set_options) { { priority: 2 } }

    it 'has priority' do
      expect(subject.priority).to eq(2)
    end
  end

  context 'arguments' do
    [
      [[], {}],
      [[1], {}],
      [[1, 2], {}],
      [[], { foo: 1 }],
      [[], { foo: 1, bar: 2 }],
      [[1], { foo: 1, bar: 2 }],
      [[1, 2], { foo: 1, bar: 2 }],
      [[Time.zone.now], {}]
    ].each do |(a, k)|
      let(:args) { a }
      let(:kwargs) { k }
      let(:expected) do
        kwargs.empty? ? [*args] : [*args, kwargs]
      end

      context [*a, k].to_s do
        it 'is expected' do
          expect(subject.arguments).to(eq(expected))
        end
      end
    end
  end

  it 'has enqueued_at' do
    expect(subject.enqueued_at.to_s).to eq(Time.zone.now.to_s)
  end

  context 'when no delay specified' do
    it 'has nil scheduled_at' do
      expect(subject.scheduled_at).to be_nil
    end
  end

  context 'when wait specified specified' do
    let(:set_options) { { wait: 1.minute } }

    it 'has scheduled_at' do
      expect(subject.scheduled_at).to eq(1.minute.from_now.to_s)
    end
  end

  context 'when wait_until specified specified' do
    let(:set_options) { { wait_until: 1.minute.from_now } }

    it 'has scheduled_at' do
      expect(subject.scheduled_at).to eq(1.minute.from_now.to_s)
    end
  end

  it 'has successfully_enqueued?' do
    expect(subject.successfully_enqueued?).to eq(true)
  end
end
