require 'unit_spec_helper'

shared_examples 'Rpush::Daemon::Store' do
  subject(:store) { described_class.new }

  let(:app) { Rpush::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT) }
  let(:notification) { Rpush::Apns::Notification.create!(device_token: "a" * 64, app: app) }
  let(:time) { Time.parse('2019/06/06 02:45').utc }
  let(:logger) { double(Rpush::Logger, error: nil, internal_logger: nil) }

  before do
    allow(Rpush).to receive_messages(logger: logger)
  end

  before(:each) do
    Timecop.freeze(time)
  end

  after do
    Timecop.return
  end

  it 'updates an notification' do
    expect(notification).to receive(:save!)
    store.update_notification(notification)
  end

  it 'updates an app' do
    expect(app).to receive(:save!)
    store.update_app(app)
  end

  it 'finds an app by ID' do
    expect(store.app(app.id)).to eq(app)
  end

  it 'finds all apps' do
    app
    expect(store.all_apps).to eq([app])
  end

  it 'translates an Integer notification ID' do
    expect(store.translate_integer_notification_id(notification.id)).to eq(notification.id)
  end

  it 'returns the pending notification count' do
    notification
    expect(store.pending_delivery_count).to eq(1)
  end

  describe 'mark_retryable' do
    it 'increments the retry count' do
      expect do
        store.mark_retryable(notification, time)
      end.to change(notification, :retries).by(1)
    end

    it 'sets the deliver after timestamp' do
      deliver_after = (time + 10.seconds)
      expect do
        store.mark_retryable(notification, deliver_after)
      end.to change(notification, :deliver_after).to(deliver_after)
    end

    it 'saves the notification without validation' do
      expect(notification).to receive(:save!).with(validate: false)
      store.mark_retryable(notification, time)
    end

    it 'does not save the notification if persist: false' do
      expect(notification).not_to receive(:save!)
      store.mark_retryable(notification, time, persist: false)
    end
  end

  describe 'mark_batch_retryable' do
    let(:deliver_after) { time + 10.seconds }

    it 'sets the attributes on the object for use in reflections' do
      store.mark_batch_retryable([notification], deliver_after)
      expect(notification.deliver_after.to_s).to eq deliver_after.to_s
      expect(notification.retries).to eq 1
    end

    it 'increments the retired count' do
      expect do
        store.mark_batch_retryable([notification], deliver_after)
        notification.reload
      end.to change(notification, :retries).by(1)
    end

    it 'sets the deliver after timestamp' do
      expect do
        store.mark_batch_retryable([notification], deliver_after)
        notification.reload
      end.to change { notification.deliver_after.try(:utc).to_s }.to(deliver_after.utc.to_s)
    end
  end

  describe 'mark_delivered' do
    it 'marks the notification as delivered' do
      expect do
        store.mark_delivered(notification, time)
      end.to change(notification, :delivered).to(true)
    end

    it 'sets the time the notification was delivered' do
      expect do
        store.mark_delivered(notification, time)
        notification.reload
      end.to change { notification.delivered_at.try(:utc).to_s }.to(time.to_s)
    end

    it 'saves the notification without validation' do
      expect(notification).to receive(:save!).with(validate: false)
      store.mark_delivered(notification, time)
    end

    it 'does not save the notification if persist: false' do
      expect(notification).not_to receive(:save!)
      store.mark_delivered(notification, time, persist: false)
    end
  end

  describe 'mark_batch_delivered' do
    it 'sets the attributes on the object for use in reflections' do
      store.mark_batch_delivered([notification])
      expect(notification.delivered_at.to_s).to eq time.to_s
      expect(notification.delivered).to be_truthy
    end

    it 'marks the notifications as delivered' do
      expect do
        store.mark_batch_delivered([notification])
        notification.reload
      end.to change(notification, :delivered).to(true)
    end

    it 'sets the time the notifications were delivered' do
      expect do
        store.mark_batch_delivered([notification])
        notification.reload
      end.to change { notification.delivered_at.try(:utc)&.to_s }.to(time.to_s)
    end
  end

  describe 'mark_failed' do
    it 'marks the notification as not delivered' do
      store.mark_failed(notification, nil, '', time)
      expect(notification.delivered).to eq(false)
    end

    it 'marks the notification as failed' do
      expect do
        store.mark_failed(notification, nil, '', time)
        notification.reload
      end.to change(notification, :failed).to(true)
    end

    it 'sets the time the notification delivery failed' do
      expect do
        store.mark_failed(notification, nil, '', time)
        notification.reload
      end.to change { notification.failed_at.try(:utc).to_s }.to(time.to_s)
    end

    it 'sets the error code' do
      expect do
        store.mark_failed(notification, 42, '', time)
      end.to change(notification, :error_code).to(42)
    end

    it 'sets the error description' do
      expect do
        store.mark_failed(notification, 42, 'Weeee', time)
      end.to change(notification, :error_description).to('Weeee')
    end

    it 'saves the notification without validation' do
      expect(notification).to receive(:save!).with(validate: false)
      store.mark_failed(notification, nil, '', time)
    end

    it 'does not save the notification if persist: false' do
      expect(notification).not_to receive(:save!)
      store.mark_failed(notification, nil, '', time, persist: false)
    end
  end

  describe 'mark_batch_failed' do
    it 'sets the attributes on the object for use in reflections' do
      store.mark_batch_failed([notification], 123, 'an error')
      expect(notification.failed_at.to_s).to eq time.to_s
      expect(notification.delivered_at).to be_nil
      expect(notification.delivered).to eq(false)
      expect(notification.failed).to be_truthy
      expect(notification.error_code).to eq 123
      expect(notification.error_description).to eq 'an error'
    end

    it 'marks the notification as not delivered' do
      store.mark_batch_failed([notification], nil, '')
      notification.reload
      expect(notification.delivered).to be_falsey
    end

    it 'marks the notification as failed' do
      expect do
        store.mark_batch_failed([notification], nil, '')
        notification.reload
      end.to change(notification, :failed).to(true)
    end

    it 'sets the time the notification delivery failed' do
      expect do
        store.mark_batch_failed([notification], nil, '')
        notification.reload
      end.to change { notification.failed_at.try(:utc) }.to(time)
    end

    it 'sets the error code' do
      expect do
        store.mark_batch_failed([notification], 42, '')
        notification.reload
      end.to change(notification, :error_code).to(42)
    end

    it 'sets the error description' do
      expect do
        store.mark_batch_failed([notification], 42, 'Weeee')
        notification.reload
      end.to change(notification, :error_description).to('Weeee')
    end
  end

  describe 'create_apns_feedback' do
    it 'creates the Feedback record' do
      expect(Rpush::Apns::Feedback).to receive(:create!).with(
        failed_at: time, device_token: 'ab' * 32, app_id: app.id
      )
      store.create_apns_feedback(time, 'ab' * 32, app)
    end
  end

  describe 'create_gcm_notification' do
    let(:data) { { 'data' => true } }
    let(:attributes) { { device_token: 'ab' * 32 } }
    let(:registration_ids) { %w[123 456] }
    let(:deliver_after) { time + 10.seconds }
    let(:args) { [attributes, data, registration_ids, deliver_after, app] }

    it 'sets the given attributes' do
      new_notification = store.create_gcm_notification(*args)
      expect(new_notification.device_token).to eq 'ab' * 32
    end

    it 'sets the given data' do
      new_notification = store.create_gcm_notification(*args)
      expect(new_notification.data['data']).to be_truthy
    end

    it 'sets the given registration IDs' do
      new_notification = store.create_gcm_notification(*args)
      expect(new_notification.registration_ids).to eq registration_ids
    end

    it 'sets the deliver_after timestamp' do
      new_notification = store.create_gcm_notification(*args)
      expect(new_notification.deliver_after).to eq deliver_after
    end

    it 'saves the new notification' do
      new_notification = store.create_gcm_notification(*args)
      expect(new_notification.new_record?).to be_falsey
    end
  end

  describe 'create_adm_notification' do
    let(:data) { { 'data' => true } }
    let(:attributes) { { app_id: app.id, collapse_key: 'ckey', delay_while_idle: true } }
    let(:registration_ids) { %w[123 456] }
    let(:deliver_after) { time + 10.seconds }
    let(:args) { [attributes, data, registration_ids, deliver_after, app] }

    it 'sets the given attributes' do
      new_notification = store.create_adm_notification(*args)
      expect(new_notification.app_id).to eq app.id
      expect(new_notification.collapse_key).to eq 'ckey'
      expect(new_notification.delay_while_idle).to be_truthy
    end

    it 'sets the given data' do
      new_notification = store.create_adm_notification(*args)
      expect(new_notification.data['data']).to be_truthy
    end

    it 'sets the given registration IDs' do
      new_notification = store.create_adm_notification(*args)
      expect(new_notification.registration_ids).to eq registration_ids
    end

    it 'sets the deliver_after timestamp' do
      new_notification = store.create_adm_notification(*args)
      expect(new_notification.deliver_after.to_s).to eq deliver_after.to_s
    end

    it 'saves the new notification' do
      new_notification = store.create_adm_notification(*args)
      expect(new_notification.new_record?).to be_falsey
    end
  end
end
