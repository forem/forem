require 'functional_spec_helper'

describe 'embedding' do
  let(:timeout) { 10 }
  let(:app) { Rpush::Apns::App.new }
  let(:notification) { Rpush::Apns::Notification.new }
  let(:tcp_socket) { double(TCPSocket, setsockopt: nil, close: nil) }
  let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket, :sync= => nil, connect: nil, write: nil, flush: nil, read: nil, close: nil) }
  let(:io_double) { double(select: nil) }

  before do
    app.certificate = TEST_CERT
    app.name = 'test'
    app.environment = 'sandbox'
    app.save!

    notification.app = app
    notification.alert = 'test'
    notification.device_token = 'a' * 108
    notification.save!

    stub_tcp_connection
  end

  def stub_tcp_connection
    allow_any_instance_of(Rpush::Daemon::TcpConnection).to receive_messages(connect_socket: [tcp_socket, ssl_socket])
    allow_any_instance_of(Rpush::Daemon::TcpConnection).to receive_messages(setup_ssl_context: double.as_null_object)
    stub_const('Rpush::Daemon::TcpConnection::IO', io_double)
    allow(Rpush::Daemon::Apns::FeedbackReceiver).to receive_messages(new: double.as_null_object)
  end

  before do
    Rpush.config.push_poll = 5
    Rpush.embed
  end

  it 'delivers a notification successfully' do
    expect do
      Timeout.timeout(timeout) do
        until notification.delivered
          notification.reload
          sleep 0.1
        end
      end
    end.to change(notification, :delivered).to(true)
  end

  after { Timeout.timeout(timeout) { Rpush.shutdown } }
end
