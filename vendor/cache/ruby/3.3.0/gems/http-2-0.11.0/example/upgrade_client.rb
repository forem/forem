# frozen_string_literals: true

require_relative 'helper'
require 'http_parser'

OptionParser.new do |opts|
  opts.banner = 'Usage: upgrade_client.rb [options]'
end.parse!

uri = URI.parse(ARGV[0] || 'http://localhost:8080/')
sock = TCPSocket.new(uri.host, uri.port)

conn = HTTP2::Client.new

def request_header_hash
  Hash.new do |hash, key|
    k = key.to_s.downcase
    k.tr! '_', '-'
    _, value = hash.find { |header_key, _| header_key.downcase == k }
    hash[key] = value if value
  end
end

conn.on(:frame) do |bytes|
  sock.print bytes
  sock.flush
end
conn.on(:frame_sent) do |frame|
  puts "Sent frame: #{frame.inspect}"
end
conn.on(:frame_received) do |frame|
  puts "Received frame: #{frame.inspect}"
end

# upgrader module
class UpgradeHandler
  UPGRADE_REQUEST = <<RESP.freeze
GET %s HTTP/1.1
Connection: Upgrade, HTTP2-Settings
HTTP2-Settings: #{HTTP2::Client.settings_header(settings_max_concurrent_streams: 100)}
Upgrade: h2c
Host: %s
User-Agent: http-2 upgrade
Accept: */*

RESP

  attr_reader :complete, :parsing
  def initialize(conn, sock)
    @conn = conn
    @sock = sock
    @headers = request_header_hash
    @body = ''.b
    @complete, @parsing = false, false
    @parser = ::HTTP::Parser.new(self)
  end

  def request(uri)
    host = "#{uri.hostname}#{":#{uri.port}" if uri.port != uri.default_port}"
    req = format(UPGRADE_REQUEST, uri.request_uri, host)
    puts req
    @sock << req
  end

  def <<(data)
    @parsing ||= true
    @parser << data
    return unless complete
    upgrade
  end

  def complete!
    @complete = true
  end

  def on_headers_complete(headers)
    @headers.merge!(headers)
    puts "received headers: #{headers}"
  end

  def on_body(chunk)
    puts "received chunk: #{chunk}"
    @body << chunk
  end

  def on_message_complete
    fail 'could not upgrade to h2c' unless @parser.status_code == 101
    @parsing = false
    complete!
  end

  def upgrade
    stream = @conn.upgrade
    log = Logger.new(stream.id)

    stream.on(:close) do
      log.info 'stream closed'
    end

    stream.on(:half_close) do
      log.info 'closing client-end of the stream'
    end

    stream.on(:headers) do |h|
      log.info "response headers: #{h}"
    end

    stream.on(:data) do |d|
      log.info "response data chunk: <<#{d}>>"
    end

    stream.on(:altsvc) do |f|
      log.info "received ALTSVC #{f}"
    end

    @conn.on(:promise) do |promise|
      promise.on(:headers) do |h|
        log.info "promise headers: #{h}"
      end

      promise.on(:data) do |d|
        log.info "promise data chunk: <<#{d.size}>>"
      end
    end

    @conn.on(:altsvc) do |f|
      log.info "received ALTSVC #{f}"
    end
  end
end

uh = UpgradeHandler.new(conn, sock)
puts 'Sending HTTP/1.1 upgrade request'
uh.request(uri)

while !sock.closed? && !sock.eof?
  data = sock.read_nonblock(1024)

  begin
    if !uh.parsing && !uh.complete
      uh << data
    elsif uh.parsing && !uh.complete
      uh << data
    elsif uh.complete
      conn << data
    end
  rescue StandardError => e
    puts "#{e.class} exception: #{e.message} - closing socket."
    e.backtrace.each { |l| puts "\t" + l }
    conn.close
    sock.close
  end
end
