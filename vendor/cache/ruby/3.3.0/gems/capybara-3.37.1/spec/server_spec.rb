# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Server do
  it 'should spool up a rack server' do
    app = proc { |_env| [200, {}, ['Hello Server!']] }
    server = described_class.new(app).boot

    res = Net::HTTP.start(server.host, server.port) { |http| http.get('/') }

    expect(res.body).to include('Hello Server')
  end

  it 'should do nothing when no server given' do
    expect do
      described_class.new(nil).boot
    end.not_to raise_error
  end

  it 'should bind to the specified host' do
    # TODO: travis with jruby in container mode has an issue with this test
    skip 'This platform has an issue with this test' if (ENV.fetch('TRAVIS', nil) && (RUBY_ENGINE == 'jruby')) || Gem.win_platform?

    begin
      app = proc { |_env| [200, {}, ['Hello Server!']] }

      Capybara.server_host = '127.0.0.1'
      server = described_class.new(app).boot
      res = Net::HTTP.get(URI("http://127.0.0.1:#{server.port}"))
      expect(res).to eq('Hello Server!')

      Capybara.server_host = '0.0.0.0'
      server = described_class.new(app).boot
      res = Net::HTTP.get(URI("http://127.0.0.1:#{server.port}"))
      expect(res).to eq('Hello Server!')
    ensure
      Capybara.server_host = nil
    end
  end

  it 'should use specified port' do
    Capybara.server_port = 22789

    app = proc { |_env| [200, {}, ['Hello Server!']] }
    server = described_class.new(app).boot

    res = Net::HTTP.start(server.host, 22789) { |http| http.get('/') }
    expect(res.body).to include('Hello Server')

    Capybara.server_port = nil
  end

  it 'should use given port' do
    app = proc { |_env| [200, {}, ['Hello Server!']] }
    server = described_class.new(app, port: 22790).boot

    res = Net::HTTP.start(server.host, 22790) { |http| http.get('/') }
    expect(res.body).to include('Hello Server')

    Capybara.server_port = nil
  end

  it 'should find an available port' do
    responses = ['Hello Server!', 'Hello Second Server!']
    apps = responses.map do |response|
      proc { |_env| [200, {}, [response]] }
    end
    servers = apps.map { |app| described_class.new(app).boot }

    servers.each_with_index do |server, idx|
      result = Net::HTTP.start(server.host, server.port) { |http| http.get('/') }
      expect(result.body).to include(responses[idx])
    end
  end

  it 'should handle that getting available ports fails randomly' do
    # Use a port to force a EADDRINUSE error to be generated
    server = TCPServer.new('0.0.0.0', 0)
    server_port = server.addr[1]
    d_server = instance_double(TCPServer, addr: [nil, server_port, nil, nil], close: nil)
    call_count = 0
    allow(TCPServer).to receive(:new).and_wrap_original do |m, *args|
      call_count.zero? ? d_server : m.call(*args)
    ensure
      call_count += 1
    end

    port = described_class.new(Object.new, host: '0.0.0.0').port
    expect(port).not_to eq(server_port)
  ensure
    server&.close
  end

  it 'should return its #base_url' do
    app = proc { |_env| [200, {}, ['Hello Server!']] }
    server = described_class.new(app).boot
    uri = ::Addressable::URI.parse(server.base_url)
    expect(uri.to_hash).to include(scheme: 'http', host: server.host, port: server.port)
  end

  it 'should call #clamp on the puma configuration to ensure that environment is a string' do
    Capybara.server = :puma
    app_proc = proc { |_env| [200, {}, ['Hello Puma!']] }
    require 'puma'
    allow(Puma::Server).to receive(:new).and_wrap_original do |method, app, events, options|
      # If #clamp is not called on the puma config then this will be a Proc
      expect(options.fetch(:environment)).to be_a(String)
      method.call(app, events, options)
    end
    server = described_class.new(app_proc).boot
    expect(Puma::Server).to have_received(:new).with(
      anything,
      anything,
      satisfy { |opts| opts.final_options[:Port] == server.port }
    )
  ensure
    Capybara.server = :default
  end

  it 'should support SSL' do
    key = File.join(Dir.pwd, 'spec', 'fixtures', 'key.pem')
    cert = File.join(Dir.pwd, 'spec', 'fixtures', 'certificate.pem')
    Capybara.server = :puma, { Host: "ssl://#{Capybara.server_host}?key=#{key}&cert=#{cert}" }
    app = proc { |_env| [200, {}, ['Hello SSL Server!']] }
    server = described_class.new(app).boot

    expect do
      Net::HTTP.start(server.host, server.port, max_retries: 0) { |http| http.get('/__identify__') }
    end.to(raise_error do |e|
      expect(e.is_a?(EOFError) || e.is_a?(Net::ReadTimeout)).to be true
    end)

    res = Net::HTTP.start(server.host, server.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
      https.get('/')
    end

    expect(res.body).to include('Hello SSL Server!')
    uri = ::Addressable::URI.parse(server.base_url)
    expect(uri.to_hash).to include(scheme: 'https', host: server.host, port: server.port)
  ensure
    Capybara.server = :default
  end

  context 'When Capybara.reuse_server is true' do
    let!(:old_reuse_server) { Capybara.reuse_server }

    before do
      Capybara.reuse_server = true
    end

    after do
      Capybara.reuse_server = old_reuse_server
    end

    it 'should use the existing server if it already running' do
      app = proc { |_env| [200, {}, ['Hello Server!']] }

      servers = Array.new(2) { described_class.new(app).boot }

      servers.each do |server|
        res = Net::HTTP.start(server.host, server.port) { |http| http.get('/') }
        expect(res.body).to include('Hello Server')
      end

      expect(servers[0].port).to eq(servers[1].port)
    end

    it 'detects and waits for all reused server sessions pending requests' do
      done = 0

      app = proc do |env|
        request = Rack::Request.new(env)
        sleep request.params['wait_time'].to_f
        done += 1
        [200, {}, ['Hello Server!']]
      end

      server1 = described_class.new(app).boot
      server2 = described_class.new(app).boot

      expect do
        start_request(server1, 1.0)
        start_request(server2, 3.0)
        server1.wait_for_pending_requests
      end.to change { done }.from(0).to(2)
      expect(server2.send(:pending_requests?)).to be(false)
    end
  end

  context 'When Capybara.reuse_server is false' do
    before do
      @old_reuse_server = Capybara.reuse_server
      Capybara.reuse_server = false
    end

    after do
      Capybara.reuse_server = @old_reuse_server # rubocop:disable RSpec/InstanceVariable
    end

    it 'should not reuse an already running server' do
      app = proc { |_env| [200, {}, ['Hello Server!']] }

      servers = Array.new(2) { described_class.new(app).boot }

      servers.each do |server|
        res = Net::HTTP.start(server.host, server.port) { |http| http.get('/') }
        expect(res.body).to include('Hello Server')
      end

      expect(servers[0].port).not_to eq(servers[1].port)
    end

    it 'detects and waits for only one sessions pending requests' do
      done = 0

      app = proc do |env|
        request = Rack::Request.new(env)
        sleep request.params['wait_time'].to_f
        done += 1
        [200, {}, ['Hello Server!']]
      end

      server1 = described_class.new(app).boot
      server2 = described_class.new(app).boot

      expect do
        start_request(server1, 1.0)
        start_request(server2, 3.0)
        server1.wait_for_pending_requests
      end.to change { done }.from(0).to(1)
      expect(server2.send(:pending_requests?)).to be(true)
      expect do
        server2.wait_for_pending_requests
      end.to change { done }.from(1).to(2)
    end
  end

  it 'should raise server errors when the server errors before the timeout' do
    Capybara.register_server :kaboom do
      sleep 0.1
      raise 'kaboom'
    end
    Capybara.server = :kaboom

    expect do
      described_class.new(proc { |e| }).boot
    end.to raise_error(RuntimeError, 'kaboom')
  ensure
    Capybara.server = :default
  end

  it 'should raise an error when there are pending requests' do
    app = proc do |env|
      request = Rack::Request.new(env)
      sleep request.params['wait_time'].to_f
      [200, {}, ['Hello Server!']]
    end

    server = described_class.new(app).boot

    expect do
      start_request(server, 59.0)
      server.wait_for_pending_requests
    end.not_to raise_error

    expect do
      start_request(server, 61.0)
      server.wait_for_pending_requests
    end.to raise_error('Requests did not finish in 60 seconds: ["/?wait_time=61.0"]')
  end

  it 'is not #responsive? when Net::HTTP raises a SystemCallError' do
    app = -> { [200, {}, ['Hello, world']] }
    server = described_class.new(app)
    allow(Net::HTTP).to receive(:start).and_raise(SystemCallError.allocate)
    expect(server.responsive?).to be false
  end

  [EOFError, Net::ReadTimeout].each do |err|
    it "should attempt an HTTPS connection if HTTP connection returns #{err}" do
      app = -> { [200, {}, ['Hello, world']] }
      ordered_errors = [Errno::ECONNREFUSED, err]
      allow(Net::HTTP).to receive(:start).with(anything, anything, hash_excluding(:use_ssl)) do
        raise ordered_errors.shift
      end
      response = Net::HTTPSuccess.allocate
      allow(response).to receive(:body).and_return app.object_id.to_s
      allow(Net::HTTP).to receive(:start).with(anything, anything, hash_including(use_ssl: true)).and_return(response).once
      described_class.new(app).boot
      expect(Net::HTTP).to have_received(:start).exactly(3).times
    end
  end

  def start_request(server, wait_time)
    # Start request, but don't wait for it to finish
    socket = TCPSocket.new(server.host, server.port)
    socket.write "GET /?wait_time=#{wait_time} HTTP/1.0\r\n\r\n"
    sleep 0.1
    socket.close
    sleep 0.1
  end
end
