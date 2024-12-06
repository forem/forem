require "unit_spec_helper"

describe Rpush::Daemon::TcpConnection do
  let(:rsa_key) { double }
  let(:certificate) { double }
  let(:password) { double }
  let(:x509_certificate) { OpenSSL::X509::Certificate.new(TEST_CERT) }
  let(:ssl_context) { double(:key= => nil, :cert= => nil, cert: x509_certificate) }
  let(:host) { 'gateway.push.apple.com' }
  let(:port) { '2195' }
  let(:tcp_socket) { double(setsockopt: nil, close: nil) }
  let(:ssl_socket) { double(:sync= => nil, connect: nil, close: nil, write: nil, flush: nil) }
  let(:logger) { double(info: nil, error: nil, warn: nil) }
  let(:app) { double(name: 'Connection 0', certificate: certificate, password: password) }
  let(:connection) { Rpush::Daemon::TcpConnection.new(app, host, port) }

  before do
    allow(OpenSSL::SSL::SSLContext).to receive_messages(new: ssl_context)
    allow(OpenSSL::PKey::RSA).to receive_messages(new: rsa_key)
    allow(OpenSSL::X509::Certificate).to receive_messages(new: x509_certificate)
    allow(TCPSocket).to receive_messages(new: tcp_socket)
    allow(OpenSSL::SSL::SSLSocket).to receive_messages(new: ssl_socket)
    allow(Rpush).to receive_messages(logger: logger)
    allow(connection).to receive(:reflect)
  end

  it "reads the number of bytes from the SSL socket" do
    expect(ssl_socket).to receive(:read).with(123)
    connection.connect
    connection.read(123)
  end

  it "selects on the SSL socket until the given timeout" do
    expect(IO).to receive(:select).with([ssl_socket], nil, nil, 10)
    connection.connect
    connection.select(10)
  end

  describe "when setting up the SSL context" do
    it "sets the key on the context" do
      expect(OpenSSL::PKey::RSA).to receive(:new).with(certificate, password).and_return(rsa_key)
      expect(ssl_context).to receive(:key=).with(rsa_key)
      connection.connect
    end

    it "sets the cert on the context" do
      expect(OpenSSL::X509::Certificate).to receive(:new).with(certificate).and_return(x509_certificate)
      expect(ssl_context).to receive(:cert=).with(x509_certificate)
      connection.connect
    end
  end

  describe "when connecting the socket" do
    it "creates a TCP socket using the configured host and port" do
      expect(TCPSocket).to receive(:new).with(host, port).and_return(tcp_socket)
      connection.connect
    end

    it "creates a new SSL socket using the TCP socket and SSL context" do
      expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(tcp_socket, ssl_context).and_return(ssl_socket)
      connection.connect
    end

    it "sets the sync option on the SSL socket" do
      expect(ssl_socket).to receive(:sync=).with(true)
      connection.connect
    end

    it "connects the SSL socket" do
      expect(ssl_socket).to receive(:connect)
      connection.connect
    end

    it "sets the socket option TCP_NODELAY" do
      expect(tcp_socket).to receive(:setsockopt).with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      connection.connect
    end

    it "sets the socket option SO_KEEPALIVE" do
      expect(tcp_socket).to receive(:setsockopt).with(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
      connection.connect
    end

    describe 'certificate expiry' do
      it 'reflects if the certificate will expire soon' do
        cert = OpenSSL::X509::Certificate.new(app.certificate)
        expect(connection).to receive(:reflect).with(:ssl_certificate_will_expire, app, cert.not_after)
        Timecop.freeze(cert.not_after - 3.days) { connection.connect }
      end

      it 'logs that the certificate will expire soon' do
        cert = OpenSSL::X509::Certificate.new(app.certificate)
        expect(logger).to receive(:warn).with("[#{app.name}] Certificate will expire at 2022-09-07 03:18:32 UTC.")
        Timecop.freeze(cert.not_after - 3.days) { connection.connect }
      end

      it 'does not reflect if the certificate will not expire soon' do
        cert = OpenSSL::X509::Certificate.new(app.certificate)
        expect(connection).not_to receive(:reflect).with(:ssl_certificate_will_expire, app, kind_of(Time))
        Timecop.freeze(cert.not_after - 2.months) { connection.connect }
      end

      it 'logs that the certificate has expired' do
        cert = OpenSSL::X509::Certificate.new(app.certificate)
        expect(logger).to receive(:error).with("[#{app.name}] Certificate expired at 2022-09-07 03:18:32 UTC.")
        Timecop.freeze(cert.not_after + 1.day) { connection.connect rescue Rpush::CertificateExpiredError }
      end

      it 'raises an error if the certificate has expired' do
        cert = OpenSSL::X509::Certificate.new(app.certificate)
        Timecop.freeze(cert.not_after + 1.day) do
          expect { connection.connect }.to raise_error(Rpush::CertificateExpiredError)
        end
      end
    end

    describe 'certificate revocation' do
      let(:cert_revoked_error) { OpenSSL::SSL::SSLError.new('certificate revoked') }
      before do
        allow(ssl_socket).to receive(:connect).and_raise(cert_revoked_error)
      end

      it 'reflects that the certificate has been revoked' do
        expect(connection).to receive(:reflect).with(:ssl_certificate_revoked, app, cert_revoked_error)
        expect { connection.connect }.to raise_error(Rpush::Daemon::TcpConnectionError, 'OpenSSL::SSL::SSLError, certificate revoked')
      end

      it 'logs that the certificate has been revoked' do
        expect(logger).to receive(:error).with('[Connection 0] Certificate has been revoked.')
        expect { connection.connect }.to raise_error(Rpush::Daemon::TcpConnectionError, 'OpenSSL::SSL::SSLError, certificate revoked')
      end
    end
  end

  describe "when shuting down the connection" do
    it "closes the TCP socket" do
      connection.connect
      expect(tcp_socket).to receive(:close)
      connection.close
    end

    it "does not attempt to close the TCP socket if it is not connected" do
      connection.connect
      expect(tcp_socket).not_to receive(:close)
      connection.instance_variable_set("@tcp_socket", nil)
      connection.close
    end

    it "closes the SSL socket" do
      connection.connect
      expect(ssl_socket).to receive(:close)
      connection.close
    end

    it "does not attempt to close the SSL socket if it is not connected" do
      connection.connect
      expect(ssl_socket).not_to receive(:close)
      connection.instance_variable_set("@ssl_socket", nil)
      connection.close
    end

    it "ignores IOError when the socket is already closed" do
      allow(tcp_socket).to receive(:close).and_raise(IOError)
      connection.connect
      connection.close
    end
  end

  shared_examples_for "when the write fails" do
    before do
      allow(connection).to receive(:sleep)
      connection.connect
      allow(ssl_socket).to receive(:write).and_raise(error)
    end

    it 'reflects the connection has been lost' do
      expect(connection).to receive(:reflect).with(:tcp_connection_lost, app, kind_of(error.class))
      expect { connection.write(nil) }.to raise_error(Rpush::Daemon::TcpConnectionError)
    end

    it "logs that the connection has been lost once only" do
      expect(logger).to receive(:error).with("[Connection 0] Lost connection to gateway.push.apple.com:2195 (#{error.class.name}, #{error.message}), reconnecting...").once
      expect { connection.write(nil) }.to raise_error(Rpush::Daemon::TcpConnectionError)
    end

    it "retries to make a connection 3 times" do
      expect(connection).to receive(:reconnect).exactly(3).times
      expect { connection.write(nil) }.to raise_error(Rpush::Daemon::TcpConnectionError)
    end

    it "raises a TcpConnectionError after 3 attempts at reconnecting" do
      expect do
        connection.write(nil)
      end.to raise_error(Rpush::Daemon::TcpConnectionError, "Connection 0 tried 3 times to reconnect but failed (#{error.class.name}, #{error.message}).")
    end

    it "sleeps 1 second before retrying the connection" do
      expect(connection).to receive(:sleep).with(1)
      expect { connection.write(nil) }.to raise_error(Rpush::Daemon::TcpConnectionError)
    end
  end

  describe "when write raises an Errno::EPIPE" do
    it_should_behave_like "when the write fails"

    def error
      Errno::EPIPE.new('an message')
    end
  end

  describe "when write raises an Errno::ETIMEDOUT" do
    it_should_behave_like "when the write fails"

    def error
      Errno::ETIMEDOUT.new('an message')
    end
  end

  describe "when write raises an OpenSSL::SSL::SSLError" do
    it_should_behave_like "when the write fails"

    def error
      OpenSSL::SSL::SSLError.new('an message')
    end
  end

  describe "when write raises an IOError" do
    it_should_behave_like "when the write fails"

    def error
      IOError.new('an message')
    end
  end

  describe "when reconnecting" do
    before { connection.connect }

    it 'closes the socket' do
      expect(connection).to receive(:close)
      connection.send(:reconnect)
    end

    it 'connects the socket' do
      expect(connection).to receive(:connect_socket)
      connection.send(:reconnect)
    end
  end

  describe "when sending a notification" do
    before { connection.connect }

    it "writes the data to the SSL socket" do
      expect(ssl_socket).to receive(:write).with("blah")
      connection.write("blah")
    end

    it "flushes the SSL socket" do
      expect(ssl_socket).to receive(:flush)
      connection.write("blah")
    end
  end

  describe 'idle period' do
    before { connection.connect }

    it 'reconnects if the connection has been idle for more than the defined period' do
      allow(Rpush::Daemon::TcpConnection).to receive_messages(idle_period: 60)
      allow(Time).to receive_messages(now: Time.now + 61)
      expect(connection).to receive(:reconnect)
      connection.write('blah')
    end

    it 'resets the last touch time' do
      now = Time.now
      allow(Time).to receive_messages(now: now)
      connection.write('blah')
      expect(connection.last_touch).to eq now
    end

    it 'does not reconnect if the connection has not been idle for more than the defined period' do
      expect(connection).not_to receive(:reconnect)
      connection.write('blah')
    end

    it 'logs the the connection is idle' do
      allow(Rpush::Daemon::TcpConnection).to receive_messages(idle_period: 60)
      allow(Time).to receive_messages(now: Time.now + 61)
      expect(Rpush.logger).to receive(:info).with('[Connection 0] Idle period exceeded, reconnecting...')
      connection.write('blah')
    end
  end
end
