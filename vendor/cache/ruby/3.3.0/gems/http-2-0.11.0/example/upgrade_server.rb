# frozen_string_literals: true

require_relative 'helper'
require 'http_parser'

options = { port: 8080 }
OptionParser.new do |opts|
  opts.banner = 'Usage: server.rb [options]'

  opts.on('-s', '--secure', 'HTTPS mode') do |v|
    options[:secure] = v
  end

  opts.on('-p', '--port [Integer]', 'listen port') do |v|
    options[:port] = v
  end
end.parse!

puts "Starting server on port #{options[:port]}"
server = TCPServer.new(options[:port])

if options[:secure]
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.cert = OpenSSL::X509::Certificate.new(File.open('keys/server.crt'))
  ctx.key = OpenSSL::PKey::RSA.new(File.open('keys/server.key'))
  ctx.npn_protocols = [DRAFT]

  server = OpenSSL::SSL::SSLServer.new(server, ctx)
end

def request_header_hash
  Hash.new do |hash, key|
    k = key.to_s.downcase
    k.tr! '_', '-'
    _, value = hash.find { |header_key, _| header_key.downcase == k }
    hash[key] = value if value
  end
end

class UpgradeHandler
  VALID_UPGRADE_METHODS = %w(GET OPTIONS).freeze
  UPGRADE_RESPONSE = <<RESP.freeze
HTTP/1.1 101 Switching Protocols
Connection: Upgrade
Upgrade: h2c

RESP

  attr_reader :complete, :headers, :body, :parsing

  def initialize(conn, sock)
    @conn, @sock = conn, sock
    @complete, @parsing = false, false
    @headers = request_header_hash
    @body = ''
    @parser = ::HTTP::Parser.new(self)
  end

  def <<(data)
    @parsing ||= true
    @parser << data
    return unless complete

    @sock.write UPGRADE_RESPONSE

    settings = headers['http2-settings']
    request = {
      ':scheme'    => 'http',
      ':method'    => @parser.http_method,
      ':authority' => headers['Host'],
      ':path'      => @parser.request_url,
    }.merge(headers)

    @conn.upgrade(settings, request, @body)
  end

  def complete!
    @complete = true
  end

  def on_headers_complete(headers)
    @headers.merge! headers
  end

  def on_body(chunk)
    @body << chunk
  end

  def on_message_complete
    fail unless VALID_UPGRADE_METHODS.include?(@parser.http_method)
    @parsing = false
    complete!
  end
end

loop do
  sock = server.accept
  puts 'New TCP connection!'

  conn = HTTP2::Server.new
  conn.on(:frame) do |bytes|
    # puts "Writing bytes: #{bytes.unpack("H*").first}"
    sock.write bytes
  end
  conn.on(:frame_sent) do |frame|
    puts "Sent frame: #{frame.inspect}"
  end
  conn.on(:frame_received) do |frame|
    puts "Received frame: #{frame.inspect}"
  end

  conn.on(:stream) do |stream|
    log = Logger.new(stream.id)
    req = request_header_hash
    buffer = ''

    stream.on(:active) { log.info 'client opened new stream' }
    stream.on(:close) do
      log.info 'stream closed'
    end

    stream.on(:headers) do |h|
      req.merge! Hash[*h.flatten]
      log.info "request headers: #{h}"
    end

    stream.on(:data) do |d|
      log.info "payload chunk: <<#{d}>>"
      buffer << d
    end

    stream.on(:half_close) do
      log.info 'client closed its end of the stream'

      if req['Upgrade']
        log.info "Processing h2c Upgrade request: #{req}"
        if req[':method'] != 'OPTIONS' # Don't respond to OPTIONS...
          response = 'Hello h2c world!'
          stream.headers({
            ':status' => '200',
            'content-length' => response.bytesize.to_s,
            'content-type' => 'text/plain',
          }, end_stream: false)
          stream.data(response)
        end
      else

        response = nil
        if req[':method'] == 'POST'
          log.info "Received POST request, payload: #{buffer}"
          response = "Hello HTTP 2.0! POST payload: #{buffer}"
        else
          log.info 'Received GET request'
          response = 'Hello HTTP 2.0! GET request'
        end

        stream.headers({
          ':status' => '200',
          'content-length' => response.bytesize.to_s,
          'content-type' => 'text/plain',
        }, end_stream: false)

        # split response into multiple DATA frames
        stream.data(response.slice!(0, 5), end_stream: false)
        stream.data(response)
      end
    end
  end

  uh = UpgradeHandler.new(conn, sock)

  while !sock.closed? && !(sock.eof? rescue true) # rubocop:disable Style/RescueModifier
    data = sock.readpartial(1024)
    # puts "Received bytes: #{data.unpack("H*").first}"

    begin
      case
      when !uh.parsing && !uh.complete

        if data.start_with?(*UpgradeHandler::VALID_UPGRADE_METHODS)
          uh << data
        else
          uh.complete!
          conn << data
        end

      when uh.parsing && !uh.complete
        uh << data

      when uh.complete
        conn << data
      end

    rescue StandardError => e
      puts "Exception: #{e}, #{e.message} - closing socket."
      puts e.backtrace.last(10).join("\n")
      sock.close
    end
  end
end

# echo foo=bar | nghttp -d - -t 0 -vu http://127.0.0.1:8080/
# nghttp -vu http://127.0.0.1:8080/
