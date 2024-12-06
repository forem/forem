require 'functional_spec_helper'

describe Rpush::CLI do
  def create_app
    app = Rpush::Apns::App.new
    app.certificate = TEST_CERT
    app.name = 'test'
    app.environment = 'sandbox'
    app.save!
    app
  end

  describe 'status' do
    let(:tcp_socket) { double(TCPSocket, setsockopt: nil, close: nil) }
    let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket, :sync= => nil, connect: nil, write: nil, flush: nil, read: nil, close: nil) }
    let(:io_double) { double(select: nil) }

    before do
      create_app
      stub_tcp_connection(tcp_socket, ssl_socket, io_double)
      Rpush.embed

      timeout do
        Thread.pass until File.exist?(Rpush::Daemon::Rpc.socket_path)
      end
    end

    after { timeout { Rpush.shutdown } }

    it 'prints the status' do
      expect(subject).to receive(:configure_rpush) { true }
      expect(subject).to receive(:puts).with(/app_runners:/)
      subject.status
    end
  end
end
