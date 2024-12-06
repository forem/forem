require 'unit_spec_helper'

describe Rpush::Daemon::Batch do
  let(:notification1) { double(:notification1, id: 1, delivered: false, failed: false) }
  let(:notification2) { double(:notification2, id: 2, delivered: false, failed: false) }
  let(:batch) { Rpush::Daemon::Batch.new([notification1, notification2]) }
  let(:store) { double.as_null_object }
  let(:time) { Time.now }

  before do
    allow(Time).to receive_messages(now: time)
    allow(Rpush::Daemon).to receive_messages(store: store)
  end

  it 'exposes the number notifications processed' do
    expect(batch.num_processed).to eq 0
  end

  it 'increments the processed notifications count' do
    expect { batch.notification_processed }.to change(batch, :num_processed).to(1)
  end

  it 'completes the batch when all notifications have been processed' do
    expect(batch).to receive(:complete)
    2.times { batch.notification_processed }
  end

  describe 'mark_delivered' do
    it 'marks the notification as delivered immediately without persisting' do
      expect(store).to receive(:mark_delivered).with(notification1, time, persist: false)
      batch.mark_delivered(notification1)
    end

    it 'defers persisting' do
      batch.mark_delivered(notification1)
      expect(batch.delivered).to eq [notification1]
    end
  end

  describe 'mark_all_delivered' do
    it 'marks the notifications as delivered immediately without persisting' do
      expect(store).to receive(:mark_delivered).with(notification1, time, persist: false)
      expect(store).to receive(:mark_delivered).with(notification2, time, persist: false)
      batch.mark_all_delivered
    end

    it 'defers persisting' do
      batch.mark_all_delivered
      expect(batch.delivered).to eq [notification1, notification2]
    end
  end

  describe 'mark_all_retryable' do
    let(:error) { StandardError.new('Exception') }

    it 'marks all notifications as retryable without persisting' do
      expect(store).to receive(:mark_retryable).ordered.with(notification1, time, persist: false)
      expect(store).to receive(:mark_retryable).ordered.with(notification2, time, persist: false)

      batch.mark_all_retryable(time, error)
    end

    it 'defers persisting' do
      batch.mark_all_retryable(time, error)
      expect(batch.retryable).to eq(time => [notification1, notification2])
    end

    context 'when one of the notifications delivered' do
      let(:notification2) { double(:notification2, id: 2, delivered: true, failed: false) }

      it 'marks all only pending notification as retryable without persisting' do
        expect(store).to receive(:mark_retryable).ordered.with(notification1, time, persist: false)
        expect(store).not_to receive(:mark_retryable).ordered.with(notification2, time, persist: false)

        batch.mark_all_retryable(time, error)
      end

      it 'defers persisting' do
        batch.mark_all_retryable(time, error)
        expect(batch.retryable).to eq(time => [notification1])
      end
    end

    context 'when one of the notifications failed' do
      let(:notification2) { double(:notification2, id: 2, delivered: false, failed: true) }

      it 'marks all only pending notification as retryable without persisting' do
        expect(store).to receive(:mark_retryable).ordered.with(notification1, time, persist: false)
        expect(store).not_to receive(:mark_retryable).ordered.with(notification2, time, persist: false)

        batch.mark_all_retryable(time, error)
      end

      it 'defers persisting' do
        batch.mark_all_retryable(time, error)
        expect(batch.retryable).to eq(time => [notification1])
      end
    end
  end

  describe 'mark_failed' do
    it 'marks the notification as failed without persisting' do
      expect(store).to receive(:mark_failed).with(notification1, 1, 'an error', time, persist: false)
      batch.mark_failed(notification1, 1, 'an error')
    end

    it 'defers persisting' do
      batch.mark_failed(notification1, 1, 'an error')
      expect(batch.failed).to eq([1, 'an error'] => [notification1])
    end
  end

  describe 'mark_failed' do
    it 'marks the notification as failed without persisting' do
      expect(store).to receive(:mark_failed).with(notification1, 1, 'an error', time, persist: false)
      expect(store).to receive(:mark_failed).with(notification2, 1, 'an error', time, persist: false)
      batch.mark_all_failed(1, 'an error')
    end

    it 'defers persisting' do
      batch.mark_all_failed(1, 'an error')
      expect(batch.failed).to eq([1, 'an error'] => [notification1, notification2])
    end
  end

  describe 'mark_retryable' do
    it 'marks the notification as retryable without persisting' do
      expect(store).to receive(:mark_retryable).with(notification1, time, persist: false)
      batch.mark_retryable(notification1, time)
    end

    it 'defers persisting' do
      batch.mark_retryable(notification1, time)
      expect(batch.retryable).to eq(time => [notification1])
    end
  end

  describe 'complete' do
    before do
      allow(Rpush).to receive_messages(logger: double.as_null_object)
      allow(batch).to receive(:reflect)
    end

    it 'identifies as complete' do
      expect do
        2.times { batch.notification_processed }
      end.to change(batch, :complete?).to(true)
    end

    it 'reflects errors raised during completion' do
      e = StandardError.new
      allow(batch).to receive(:complete_delivered).and_raise(e)
      expect(batch).to receive(:reflect).with(:error, e)
      2.times { batch.notification_processed }
    end

    describe 'delivered' do
      def complete
        [notification1, notification2].each do |n|
          batch.mark_delivered(n)
          batch.notification_processed
        end
      end

      it 'marks the batch as delivered' do
        expect(store).to receive(:mark_batch_delivered).with([notification1, notification2])
        complete
      end

      it 'reflects the notifications were delivered' do
        expect(batch).to receive(:reflect).with(:notification_delivered, notification1)
        expect(batch).to receive(:reflect).with(:notification_delivered, notification2)
        complete
      end
    end

    describe 'failed' do
      def complete
        [notification1, notification2].each do |n|
          batch.mark_failed(n, 1, 'an error')
          batch.notification_processed
        end
      end

      it 'marks the batch as failed' do
        expect(store).to receive(:mark_batch_failed).with([notification1, notification2], 1, 'an error')
        complete
      end

      it 'reflects the notifications failed' do
        expect(batch).to receive(:reflect).with(:notification_failed, notification1)
        expect(batch).to receive(:reflect).with(:notification_failed, notification2)
        complete
      end
    end

    describe 'retryable' do
      def complete
        [notification1, notification2].each do |n|
          batch.mark_retryable(n, time)
          batch.notification_processed
        end
      end

      it 'marks the batch as retryable' do
        expect(store).to receive(:mark_batch_retryable).with([notification1, notification2], time)
        complete
      end

      it 'reflects the notifications will be retried' do
        expect(batch).to receive(:reflect).with(:notification_will_retry, notification1)
        expect(batch).to receive(:reflect).with(:notification_will_retry, notification2)
        complete
      end
    end
  end
end
