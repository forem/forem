require 'unit_spec_helper'

describe Rpush::Daemon::Wns::Delivery do
  let(:app) { Rpush::Wns::App.create!(name: "MyApp", client_id: "someclient", client_secret: "somesecret", access_token: "access_token", access_token_expiration: Time.now + (60 * 10)) }
  let(:notification) { Rpush::Wns::Notification.create!(app: app, data: { title: "MyApp", body: "Example notification", param: "/param1" }, uri: "http://some.example/", deliver_after: Time.now) }
  let(:logger) { double(error: nil, info: nil, warn: nil) }
  let(:response) { double(code: 200, header: {}, body: '') }
  let(:http) { double(shutdown: nil, request: response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(mark_failed: nil, mark_delivered: nil, mark_retryable: nil, notification_processed: nil) }
  let(:delivery) { Rpush::Daemon::Wns::Delivery.new(app, http, notification, batch) }
  let(:store) { double(create_wpns_notification: double(id: 2), update_app: nil) }

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

  shared_examples_for "an notification with some delivery faliures" do
    let(:new_notification) { Rpush::Wns::Notification.where('id != ?', notification.id).first }

    before { allow(response).to receive_messages(body: JSON.dump(body)) }

    it "marks the original notification falied" do
      expect(delivery).to receive(:mark_failed) do |error|
        expect(error.message).to match(error_description)
      end
      perform_with_rescue
    end

    it "raises a DeliveryError" do
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe "an 200 response without an access token" do
    before do
      allow(app).to receive_messages(access_token_expired?: true)
      allow(response).to receive_messages(to_hash: {}, code: 200, body: JSON.dump(access_token: "dummy_access_token", expires_in: 60))
    end

    it 'set the access token for the app' do
      expect(delivery).to receive(:update_access_token).with("access_token" => "dummy_access_token", "expires_in" => 60)
      expect(store).to receive(:update_app).with app
      perform
    end

    it 'uses the PostRequest factory for creating the request' do
      expect(Rpush::Daemon::Wns::PostRequest).to receive(:create).with(notification, "dummy_access_token")
      perform
    end
  end

  describe "an 200 response with a valid access token" do
    before do
      allow(response).to receive_messages(code: 200)
    end

    it "marks the notification as delivered if delivered successfully to all devices" do
      allow(response).to receive_messages(body: JSON.dump("failure" => 0))
      allow(response).to receive_messages(to_hash: { "X-WNS-Status" => ["received"] })
      expect(batch).to receive(:mark_delivered).with(notification)
      perform
    end

    it "retries the notification when the queue is full" do
      allow(response).to receive_messages(body: JSON.dump("failure" => 0))
      allow(response).to receive_messages(to_hash: { "X-WNS-Status" => ["channelthrottled"] })
      expect(batch).to receive(:mark_retryable).with(notification, Time.now + (60 * 10))
      perform
    end

    it "marks the notification as failed if the notification is suppressed" do
      allow(response).to receive_messages(body: JSON.dump("faliure" => 0))
      allow(response).to receive_messages(to_hash: { "X-WNS-Status" => ["dropped"], "X-WNS-Error-Description" => "" })
      error = Rpush::DeliveryError.new(200, notification.id, 'Notification was received but suppressed by the service ().')
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 400 response" do
    before { allow(response).to receive_messages(code: 400) }
    it "marks notifications as failed" do
      error = Rpush::DeliveryError.new(400, notification.id, 'One or more headers were specified incorrectly or conflict with another header.')
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 404 response" do
    before { allow(response).to receive_messages(code: 404) }
    it "marks notifications as failed" do
      error = Rpush::DeliveryError.new(404, notification.id, 'The channel URI is not valid or is not recognized by WNS.')
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 405 response" do
    before { allow(response).to receive_messages(code: 405) }
    it "marks notifications as failed" do
      error = Rpush::DeliveryError.new(405, notification.id, 'Invalid method (GET, CREATE); only POST (Windows or Windows Phone) or DELETE (Windows Phone only) is allowed.')
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 406 response" do
    before { allow(response).to receive_messages(code: 406) }

    it "retries the notification" do
      expect(batch).to receive(:mark_retryable).with(notification, Time.now + (60 * 60))
      perform
    end

    it "logs a warning that the notification will be retried" do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] Per-day throttling limit reached. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end
  end

  describe "an 412 response" do
    before { allow(response).to receive_messages(code: 412) }

    it "retries the notification" do
      expect(batch).to receive(:mark_retryable).with(notification, Time.now + (60 * 60))
      perform
    end

    it "logs a warning that the notification will be retried" do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] Device unreachable. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end
  end

  describe "an 503 response" do
    before { allow(response).to receive_messages(code: 503) }

    it "retries the notification exponentially" do
      expect(delivery).to receive(:mark_retryable_exponential).with(notification)
      perform
    end

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] Service Unavailable. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
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
