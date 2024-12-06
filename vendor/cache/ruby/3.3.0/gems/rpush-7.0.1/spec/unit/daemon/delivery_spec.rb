require 'unit_spec_helper'

describe Rpush::Daemon::Delivery do
  class DeliverySpecDelivery < Rpush::Daemon::Delivery
    def initialize(batch)
      @batch = batch
    end
  end

  let(:now) { Time.parse("2014-10-14 00:00:00") }
  let(:batch) { double(Rpush::Daemon::Batch) }
  let(:delivery) { DeliverySpecDelivery.new(batch) }
  let(:notification) { Rpush::Apns::Notification.new }

  before { allow(Time).to receive_messages(now: now) }

  describe 'mark_retryable' do
    it 'does not retry a notification with an expired fail_after' do
      expect(batch).to receive(:mark_failed).with(notification, nil, "Notification failed to be delivered before 2014-10-13 23:00:00.")
      notification.fail_after = Time.now - 1.hour
      delivery.mark_retryable(notification, Time.now + 1.hour)
    end

    it 'retries the notification if does not have a fail_after time' do
      expect(batch).to receive(:mark_retryable)
      notification.fail_after = nil
      delivery.mark_retryable(notification, Time.now + 1.hour)
    end

    it 'retries the notification if the fail_after time has not been reached' do
      expect(batch).to receive(:mark_retryable)
      notification.fail_after = Time.now + 1.hour
      delivery.mark_retryable(notification, Time.now + 1.hour)
    end
  end

  describe 'mark_batch_delivered' do
    it 'marks all notifications as delivered' do
      expect(batch).to receive(:mark_all_delivered)
      delivery.mark_batch_delivered
    end
  end

  describe 'mark_batch_retryable' do
    let(:batch) { double(Rpush::Daemon::Batch) }
    let(:error) { StandardError.new('Exception') }

    it 'marks all notifications as retryable' do
      expect(batch).to receive(:mark_all_retryable)
      delivery.mark_batch_retryable(Time.now + 1.hour, error)
    end
  end

  describe 'mark_batch_failed' do
    it 'marks all notifications as delivered' do
      error = Rpush::DeliveryError.new(1, 42, 'an error')
      expect(batch).to receive(:mark_all_failed).with(1, 'Unable to deliver notification 42, received error 1 (an error)')
      delivery.mark_batch_failed(error)
    end
  end
end
