require 'functional_spec_helper'

describe 'APNs http2 adapter' do
  let(:fake_client) {
    double(
      prepare_request: fake_http2_request,
      close:           'ok',
      call_async:      'ok',
      join:            'ok',
      on:              'ok'
    )
  }
  let(:app) { create_app }
  let(:fake_device_token) { 'a' * 108 }
  let(:fake_http2_request) { double }
  let(:fake_http_resp_headers) {
    {
      ":status" => "200",
      "apns-id"=>"C6D65840-5E3F-785A-4D91-B97D305C12F6"
    }
  }
  let(:fake_http_resp_body) { '' }
  let(:notification_data) { nil }

  before do
    Rpush.config.push_poll = 0.5
    allow(NetHttp2::Client).
      to receive(:new).and_return(fake_client)
    allow(fake_http2_request).
      to receive(:on).with(:headers).
      and_yield(fake_http_resp_headers)
    allow(fake_http2_request).
      to receive(:on).with(:body_chunk).
      and_yield(fake_http_resp_body)
    allow(fake_http2_request).
      to receive(:on).with(:close).
      and_yield
  end

  def create_app
    app = Rpush::Apns2::App.new
    app.certificate = TEST_CERT
    app.name = 'test'
    app.environment = 'development'
    app.bundle_id = 'com.example.app'
    app.save!
    app
  end

  def create_notification
    notification = Rpush::Apns2::Notification.new
    notification.app = app
    notification.sound = 'default'
    notification.alert = 'test'
    notification.device_token = fake_device_token
    notification.data = notification_data
    notification.content_available = 1
    notification.save!
    notification
  end

  it 'delivers a notification successfully' do
    notification = create_notification

    thread = nil
    expect(fake_http2_request).
      to receive(:on).with(:close) { |&block|
        # imitate HTTP2 delay
        thread = Thread.new { sleep(0.01); block.call }
      }
    expect(fake_client).to receive(:join) { thread.join }

    expect(fake_client)
      .to receive(:prepare_request)
      .with(
        :post,
        "/3/device/#{fake_device_token}",
        { body: "{\"aps\":{\"alert\":\"test\",\"sound\":\"default\",\"content-available\":1}}",
          headers: {
            'apns-expiration' => '0',
            'apns-priority' => '10',
            'apns-topic' => 'com.example.app',
            'apns-push-type' => 'background'
          }
        }
      )
      .and_return(fake_http2_request)

    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  context 'when there is "headers" field in a data' do
    let(:bundle_id) { 'some.example.com' }
    let(:notification_data) {
      {
        'headers' => { 'apns-topic' => bundle_id },
        'some_field' =>  'some value'
      }
    }

    it 'delivers notification with custom headers' do
      notification = create_notification

      expect(fake_client)
        .to receive(:prepare_request)
        .with(
          :post,
          "/3/device/#{fake_device_token}",
          { body: "{\"aps\":{\"alert\":\"test\",\"sound\":\"default\","\
                  "\"content-available\":1},\"some_field\":\"some value\"}",
            headers: {
              'apns-topic' => bundle_id,
              'apns-expiration' => '0',
              'apns-priority' => '10',
              'apns-push-type' => 'background'
            }
          }
        ).and_return(fake_http2_request)

      expect do
        Rpush.push
        notification.reload
      end.to change(notification, :delivered).to(true)
    end
  end

  describe 'delivery failures' do
    context 'when response is about incorrect request' do
      let(:fake_http_resp_headers) {
        {
          ":status" => "404",
          "apns-id"=>"C6D65840-5E3F-785A-4D91-B97D305C12F6"
        }
      }

      it 'fails to deliver a notification' do
        notification = create_notification
        expect do
          Rpush.push
          notification.reload
        end.to change(notification, :failed).to(true)
      end

      it 'reflects :notification_id_failed' do
        Rpush.reflect do |on|
          on.notification_id_failed do |app, id, code, descr|
            expect(app).to be_kind_of(Rpush::Client::Apns2::App)
            expect(id).to eq 1
            expect(code).to eq 404
            expect(descr).to be_nil
          end
        end

        notification = create_notification
        Rpush.push
      end
    end

    context 'when response returns 500 error for APNs maintenance' do
      let(:fake_http_resp_headers) {
        {
          ":status" => "500",
          "apns-id"=>"C6D65840-5E3F-785A-4D91-B97D305C12F6"
        }
      }

      it 'fails but retries delivery several times' do
        notification = create_notification
        expect do
          Rpush.push
          notification.reload
        end.to change(notification, :retries)
      end

      it 'reflects :notification_id_will_retry' do
        Rpush.reflect do |on|
          on.notification_id_will_retry do |app, id, timer|
            expect(app).to be_kind_of(Rpush::Client::Apns2::App)
            expect(id).to eq 1
          end
        end

        notification = create_notification
        Rpush.push
      end
    end

    context 'when there is SocketError' do
      let(:fake_http_resp_headers) {
        {
          ":status" => "500",
          "apns-id"=>"C6D65840-5E3F-785A-4D91-B97D305C12F6"
        }
      }

      before(:each) do
        expect(fake_client).to receive(:call_async) { raise(SocketError) }
      end

      it 'fails but retries delivery several times' do
        notification = create_notification
        expect do
          Rpush.push
          notification.reload
        end.to change(notification, :retries)
      end

      it 'reflects :notification_id_will_retry' do
        Rpush.reflect do |on|
          on.notification_id_will_retry do |app, id, timer|
            expect(app).to be_kind_of(Rpush::Client::Apns2::App)
            expect(id).to eq 1
            expect(timer).to be_kind_of(Time)
          end
        end

        notification = create_notification
        Rpush.push
      end

      context 'when specific notification was delivered before request failed' do
        let(:fake_http_resp_headers) {
          {
            ":status" => "200",
            "apns-id"=>"C6D65840-5E3F-785A-4D91-B97D305C12F6"
          }
        }

        it 'fails but will not retry this notification' do
          notification = create_notification
          expect do
            Rpush.push
            notification.reload
          end.to change(notification, :retries).by(0)
             .and change(notification, :delivered).to(true)
        end
      end
    end

    context 'when any StandardError occurs' do
      before(:each) do
        expect(fake_client).to receive(:call_async) { raise(StandardError) }
      end

      it 'marks notification failed' do
        notification = create_notification
        expect do
          Rpush.push
          notification.reload
        end.to change(notification, :failed).to(true)
      end

      it 'reflects :error' do
        Rpush.reflect do |on|
          on.error do |error|
            expect(error).to be_kind_of(StandardError)
           reflector.accept
          end
        end

        notification = create_notification
        Rpush.push
      end
    end

    context 'when waiting for requests to complete times out' do
      let(:on_close) do
        proc { |&block| @thread = Thread.new { sleep(0.01) } }
      end

      before(:each) do
        @thread = nil

        expect(fake_http2_request).
          to receive(:on).with(:close), &on_close

        expect(fake_client).to receive(:join) { @thread.join; raise(NetHttp2::AsyncRequestTimeout) }
      end

      it 'closes the client' do
        create_notification
        expect(fake_client).to receive(:close)
        Rpush.push
      end

      it 'reflects :error' do
        reflected_error = false
        Rpush.reflect do |on|
          on.error do |error|
            reflected_error = true
            expect(error).to be_kind_of(StandardError)
            reflector.accept
          end
        end

        notification = create_notification
        Rpush.push

        expect(reflected_error).to be true
      end

      it 'fails but retries delivery several times' do
        notification = create_notification
        expect do
          Rpush.push
          notification.reload
        end.to change(notification, :retries)
      end

      context 'when specific notification was delivered before another async call failed' do
        let(:on_close) do
          proc { |&block| @thread = Thread.new { sleep(0.01); block.call } }
        end

        it 'fails but retries delivery several times' do
          notification = create_notification
          expect do
            Rpush.push
            notification.reload
          end.to change(notification, :retries).by(0)
             .and change(notification, :delivered).to(true)
        end
      end
    end
  end
end
