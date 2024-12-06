require 'unit_spec_helper'

describe Rpush::Daemon::Wns::PostRequest do
  let(:app) do
    Rpush::Wns::App.create!(
      name: "MyApp",
      client_id: "someclient",
      client_secret: "somesecret",
      access_token: "access_token",
      access_token_expiration: Time.now + (60 * 10)
    )
  end

  context 'Notification' do
    let(:notification) do
      Rpush::Wns::Notification.create!(
        app: app,
        data: {
          title: "MyApp",
          body: "Example notification"
        },
        uri: "http://some.example/"
      )
    end

    it 'creates a request characteristic for toast notification' do
      request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
      expect(request['X-WNS-Type']).to eq('wns/toast')
      expect(request['Content-Type']).to eq('text/xml')
      expect(request.body).to include('<toast>')
      expect(request.body).to include('MyApp')
      expect(request.body).to include('Example notification')
      # no priority header
      expect { request.fetch('X-WNS-PRIORITY') }.to raise_error(KeyError)
    end

    context 'with launch' do
      let(:notification) do
        Rpush::Wns::Notification.create!(
          app: app,
          data: {
            title: "MyApp",
            body: "Example notification",
            launch: "MyLaunchArgument"
          },
          uri: "http://some.example/"
        )
      end

      it 'creates a request characteristic for toast notification with launch' do
        request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
        expect(request['X-WNS-Type']).to eq('wns/toast')
        expect(request['Content-Type']).to eq('text/xml')
        expect(request.body).to include("<toast launch='MyLaunchArgument'>")
        expect(request.body).to include('MyApp')
        expect(request.body).to include('Example notification')
      end
    end

    context 'with priority' do
      let(:notification) do
        Rpush::Wns::Notification.create!(
          app: app,
          data: {
            title: "MyApp",
            body: "Example notification"
          },
          uri: "http://some.example/",
          priority: 1
        )
      end

      it 'creates a request characteristic for toast notification with priority' do
        request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
        expect(request['X-WNS-Type']).to eq('wns/toast')
        expect(request['Content-Type']).to eq('text/xml')
        expect(request['X-WNS-PRIORITY']).to eq('1')
        expect(request.body).to include('MyApp')
        expect(request.body).to include('Example notification')
      end
    end

    context 'with sound' do
      let(:notification) do
        Rpush::Wns::Notification.create!(
          app: app,
          data: {
            title: "MyApp",
            body: "Example notification"
          },
          uri: "http://some.example/",
          sound: "ms-appx:///examplesound.wav"
        )
      end

      it 'creates a request characteristic for toast notification' do
        request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
        expect(request['X-WNS-Type']).to eq('wns/toast')
        expect(request['Content-Type']).to eq('text/xml')
        expect(request.body).to include('<toast>')
        expect(request.body).to include('MyApp')
        expect(request.body).to include('Example notification')
        expect(request.body).to include("<audio src='ms-appx:///examplesound.wav'/>")
      end
    end
  end

  context 'RawNotification' do
    let(:notification) do
      Rpush::Wns::RawNotification.create!(
        app: app,
        data: { foo: 'foo', bar: 'bar' },
        uri: "http://some.example/"
      )
    end

    it 'creates a request characteristic for raw notification' do
      request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
      expect(request['X-WNS-Type']).to eq('wns/raw')
      expect(request['Content-Type']).to eq('application/octet-stream')
      expect(request.body).to eq("{\"foo\":\"foo\",\"bar\":\"bar\"}")
    end

    context 'with priority' do
      let(:notification) do
        Rpush::Wns::RawNotification.create!(
          app: app,
          data: { foo: 'foo', bar: 'bar' },
          uri: "http://some.example/",
          priority: 3
        )
      end

      it 'creates a request characteristic for raw notification with priority' do
        request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
        expect(request['X-WNS-Type']).to eq('wns/raw')
        expect(request['X-WNS-PRIORITY']).to eq('3')
        expect(request['Content-Type']).to eq('application/octet-stream')
        expect(request.body).to eq("{\"foo\":\"foo\",\"bar\":\"bar\"}")
      end
    end
  end

  context 'BadgeNotification' do
    let(:notification) do
      Rpush::Wns::BadgeNotification.create!(
        app: app,
        uri: "http://some.example/",
        badge: 42
      )
    end

    it 'creates a request characteristic for badge notification' do
      request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
      expect(request['X-WNS-Type']).to eq('wns/badge')
      expect(request['Content-Type']).to eq('text/xml')
      expect(request.body).to include('<badge')
      expect(request.body).to include('42')
    end

    context 'with priority' do
      let(:notification) do
        Rpush::Wns::BadgeNotification.create!(
          app: app,
          uri: "http://some.example/",
          badge: 42,
          priority: 4
        )
      end

      it 'creates a request characteristic for badge notification with priority' do
        request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
        expect(request['X-WNS-Type']).to eq('wns/badge')
        expect(request['X-WNS-PRIORITY']).to eq('4')
        expect(request['Content-Type']).to eq('text/xml')
        expect(request.body).to include('<badge')
        expect(request.body).to include('42')
      end
    end
  end
end
