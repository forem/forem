require 'unit_spec_helper'

describe Rpush::Daemon::Gcm::Delivery do
  let(:app) { Rpush::Gcm::App.create!(name: 'MyApp', auth_key: 'abc123') }
  let(:notification) { Rpush::Gcm::Notification.create!(app: app, registration_ids: ['xyz'], deliver_after: Time.now) }
  let(:logger) { double(error: nil, info: nil, warn: nil) }
  let(:response) { double(code: 200, header: {}) }
  let(:http) { double(shutdown: nil, request: response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(mark_failed: nil, mark_delivered: nil, mark_retryable: nil, notification_processed: nil) }
  let(:delivery) { Rpush::Daemon::Gcm::Delivery.new(app, http, notification, batch) }
  let(:store) { double(create_gcm_notification: double(id: 2)) }

  def perform
    delivery.perform
  end

  def perform_with_rescue
    expect { perform }.to raise_error(StandardError)
  end

  before do
    allow(delivery).to receive_messages(reflect: nil)
    allow(Rpush::Daemon).to receive_messages(store: store)
    allow(Time).to receive_messages(now: now)
    allow(Rpush).to receive_messages(logger: logger)
  end

  shared_examples_for 'a notification with some delivery failures' do
    let(:new_notification) { Rpush::Gcm::Notification.where('id != ?', notification.id).first }

    before { allow(response).to receive_messages(body: JSON.dump(body)) }

    it 'marks the original notification as failed' do
      # error = Rpush::DeliveryError.new(nil, notification.id, error_description)
      expect(delivery).to receive(:mark_failed) do |error|
        expect(error.to_s).to match(error_description)
      end
      perform_with_rescue
    end

    it 'creates a new notification for the unavailable devices' do
      notification.update(registration_ids: %w(id_0 id_1 id_2), data: { 'one' => 1 }, collapse_key: 'thing', delay_while_idle: true)
      allow(response).to receive_messages(header: { 'retry-after' => 10 })
      attrs = { 'collapse_key' => 'thing', 'delay_while_idle' => true, 'app_id' => app.id }
      expect(store).to receive(:create_gcm_notification).with(attrs, notification.data,
                                                              %w(id_0 id_2), now + 10.seconds, notification.app)
      perform_with_rescue
    end

    it 'raises a DeliveryError' do
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe 'a 200 response' do
    before do
      allow(response).to receive_messages(code: 200)
    end

    it 'reflects on any IDs which successfully received the notification' do
      body = {
        'failure' => 1,
        'success' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'Err' }
        ]
      }

      allow(response).to receive_messages(body: JSON.dump(body))
      allow(notification).to receive_messages(registration_ids: %w(1 2))
      expect(delivery).to receive(:reflect).with(:gcm_delivered_to_recipient, notification, '1')
      expect(delivery).not_to receive(:reflect).with(:gcm_delivered_to_recipient, notification, '2')
      perform_with_rescue
    end

    it 'reflects on any IDs which failed to receive the notification' do
      body = {
        'failure' => 1,
        'success' => 1,
        'results' => [
          { 'error' => 'Err' },
          { 'message_id' => '1:000' }
        ]
      }

      allow(response).to receive_messages(body: JSON.dump(body))
      allow(notification).to receive_messages(registration_ids: %w(1 2))
      expect(delivery).to receive(:reflect).with(:gcm_failed_to_recipient, notification, 'Err', '1')
      expect(delivery).not_to receive(:reflect).with(:gcm_failed_to_recipient, notification, anything, '2')
      perform_with_rescue
    end

    it 'reflects on canonical IDs' do
      body = {
        'failure' => 0,
        'success' => 3,
        'canonical_ids' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'message_id' => '1:000', 'registration_id' => 'canonical123' },
          { 'message_id' => '1:000' }
        ] }

      allow(response).to receive_messages(body: JSON.dump(body))
      allow(notification).to receive_messages(registration_ids: %w(1 2 3))
      expect(delivery).to receive(:reflect).with(:gcm_canonical_id, '2', 'canonical123')
      perform
    end

    it 'reflects on invalid IDs' do
      body = {
        'failure' => 1,
        'success' => 2,
        'canonical_ids' => 0,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'NotRegistered' },
          { 'message_id' => '1:000' }
        ]
      }

      allow(response).to receive_messages(body: JSON.dump(body))
      allow(notification).to receive_messages(registration_ids: %w(1 2 3))
      expect(delivery).to receive(:reflect).with(:gcm_invalid_registration_id, app, 'NotRegistered', '2')
      perform_with_rescue
    end

    describe 'when delivered successfully to all devices' do
      let(:body) do
        {
          'failure' => 0,
          'success' => 1,
          'results' => [{ 'message_id' => '1:000' }]
        }
      end

      before { allow(response).to receive_messages(body: JSON.dump(body)) }

      it 'marks the notification as delivered' do
        expect(delivery).to receive(:mark_delivered)
        perform
      end

      it 'logs that the notification was delivered' do
        expect(logger).to receive(:info).with("[MyApp] #{notification.id} sent to xyz")
        perform
      end
    end

    it 'marks a notification as failed if any ids are invalid' do
      body = {
        'failure' => 1,
        'success' => 2,
        'canonical_ids' => 0,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'NotRegistered' },
          { 'message_id' => '1:000' }
        ]
      }

      allow(response).to receive_messages(body: JSON.dump(body))
      expect(delivery).to receive(:mark_failed)
      expect(delivery).not_to receive(:mark_retryable)
      expect(store).not_to receive(:create_gcm_notification)
      perform_with_rescue
    end

    it 'marks a notification as failed if any deliveries failed that cannot be retried' do
      body = {
        'failure' => 1,
        'success' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'InvalidDataKey' }
        ] }
      allow(response).to receive_messages(body: JSON.dump(body))
      error = Rpush::DeliveryError.new(nil, notification.id, 'Failed to deliver to all recipients. Errors: InvalidDataKey.')
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end

    describe 'all deliveries failed with Unavailable or InternalServerError' do
      let(:body) do
        {
          'failure' => 2,
          'success' => 0,
          'results' => [
            { 'error' => 'Unavailable' },
            { 'error' => 'Unavailable' }
          ]
        }
      end

      before do
        allow(response).to receive_messages(body: JSON.dump(body))
        allow(notification).to receive_messages(registration_ids: %w(1 2))
      end

      it 'retries the notification respecting the Retry-After header' do
        allow(response).to receive_messages(header: { 'retry-after' => 10 })
        expect(delivery).to receive(:mark_retryable).with(notification, now + 10.seconds)
        perform
      end

      it 'retries the notification using exponential back-off if the Retry-After header is not present' do
        expect(delivery).to receive(:mark_retryable).with(notification, now + 2)
        perform
      end

      it 'does not mark the notification as failed' do
        expect(delivery).not_to receive(:mark_failed)
        perform
      end

      it 'logs that the notification will be retried' do
        notification.retries = 1
        notification.deliver_after = now + 2
        expect(Rpush.logger).to receive(:warn).with("[MyApp] All recipients unavailable. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
        perform
      end
    end

    describe 'all deliveries failed with some as Unavailable or InternalServerError' do
      let(:body) do
        { 'failure' => 3,
          'success' => 0,
          'results' => [
            { 'error' => 'Unavailable' },
            { 'error' => 'InvalidDataKey' },
            { 'error' => 'Unavailable' }
          ]
        }
      end
      let(:error_description) { /#{Regexp.escape("Failed to deliver to recipients 0, 1, 2. Errors: Unavailable, InvalidDataKey, Unavailable. 0, 2 will be retried as notification")} [\d]+\./ }
      it_should_behave_like 'a notification with some delivery failures'
    end

    describe 'some deliveries failed with Unavailable or InternalServerError' do
      let(:body) do
        { 'failure' => 2,
          'success' => 1,
          'results' => [
            { 'error' => 'Unavailable' },
            { 'message_id' => '1:000' },
            { 'error' => 'InternalServerError' }
          ]
        }
      end
      let(:error_description) { /#{Regexp.escape("Failed to deliver to recipients 0, 2. Errors: Unavailable, InternalServerError. 0, 2 will be retried as notification")} [\d]+\./ }
      it_should_behave_like 'a notification with some delivery failures'
    end
  end

  describe 'a 503 response' do
    before { allow(response).to receive_messages(code: 503) }

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] GCM responded with an Service Unavailable Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 10 })
      expect(delivery).to receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'respects a HTTP-date Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      expect(delivery).to receive(:mark_retryable).with(notification, Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
      perform
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**1)
      perform
    end
  end

  describe 'a 502 response' do
    before { allow(response).to receive_messages(code: 502) }

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] GCM responded with a Bad Gateway Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 10 })
      expect(delivery).to receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'respects a HTTP-date Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      expect(delivery).to receive(:mark_retryable).with(notification, Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
      perform
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**1)
      perform
    end
  end

  describe 'a 500 response' do
    before do
      notification.update_attribute(:retries, 2)
      allow(response).to receive_messages(code: 500)
    end

    it 'logs a warning that the notification has been re-queued.' do
      notification.retries = 3
      notification.deliver_after = now + 2**3
      expect(Rpush.logger).to receive(:warn).with("[MyApp] GCM responded with an Internal Error. Notification #{notification.id} will be retried after #{(now + 2**3).strftime('%Y-%m-%d %H:%M:%S')} (retry 3).")
      perform
    end

    it 'retries the notification in accordance with the exponential back-off strategy.' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**3)
      perform
    end
  end

  describe 'a 5xx response' do
    before { allow(response).to receive_messages(code: 555) }

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] GCM responded with a 5xx Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 10 })
      expect(delivery).to receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'respects a HTTP-date Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      expect(delivery).to receive(:mark_retryable).with(notification, Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
      perform
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**1)
      perform
    end
  end

  describe 'a 401 response' do
    before { allow(response).to receive_messages(code: 401) }

    it 'raises an error' do
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe 'a 400 response' do
    before { allow(response).to receive_messages(code: 400) }

    it 'marks the notification as failed' do
      error = Rpush::DeliveryError.new(400, notification.id, 'GCM failed to parse the JSON request. Possibly an Rpush bug, please open an issue.')
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe 'an un-handled response' do
    before { allow(response).to receive_messages(code: 418) }

    it 'marks the notification as failed' do
      error = Rpush::DeliveryError.new(418, notification.id, "I'm a Teapot")
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end
end
