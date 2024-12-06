require_relative 'helper'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: client.rb [options]'

  opts.on('-d', '--data [String]', 'HTTP payload') do |v|
    options[:payload] = v
  end
end.parse!

uri = URI.parse(ARGV[0] || 'http://localhost:8080/')
tcp = TCPSocket.new(uri.host, uri.port)
sock = nil

if uri.scheme == 'https'
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

  # For ALPN support, Ruby >= 2.3 and OpenSSL >= 1.0.2 are required

  ctx.alpn_protocols = [DRAFT]
  ctx.alpn_select_cb = lambda do |protocols|
    puts "ALPN protocols supported by server: #{protocols}"
    DRAFT if protocols.include? DRAFT
  end

  sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
  sock.sync_close = true
  sock.hostname = uri.hostname
  sock.connect

  if sock.alpn_protocol != DRAFT
    puts "Failed to negotiate #{DRAFT} via ALPN"
    exit
  end
else
  sock = tcp
end

conn = HTTP2::Client.new
stream = conn.new_stream
log = Logger.new(stream.id)

conn.on(:frame) do |bytes|
  # puts "Sending bytes: #{bytes.unpack("H*").first}"
  sock.print bytes
  sock.flush
end
conn.on(:frame_sent) do |frame|
  puts "Sent frame: #{frame.inspect}"
end
conn.on(:frame_received) do |frame|
  puts "Received frame: #{frame.inspect}"
end

conn.on(:promise) do |promise|
  promise.on(:promise_headers) do |h|
    log.info "promise request headers: #{h}"
  end

  promise.on(:headers) do |h|
    log.info "promise headers: #{h}"
  end

  promise.on(:data) do |d|
    log.info "promise data chunk: <<#{d.size}>>"
  end
end

conn.on(:altsvc) do |f|
  log.info "received ALTSVC #{f}"
end

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

head = {
  ':scheme' => uri.scheme,
  ':method' => (options[:payload].nil? ? 'GET' : 'POST'),
  ':authority' => [uri.host, uri.port].join(':'),
  ':path' => uri.path,
  'accept' => '*/*',
}

puts 'Sending HTTP 2.0 request'
if head[':method'] == 'GET'
  stream.headers(head, end_stream: true)
else
  stream.headers(head, end_stream: false)
  stream.data(options[:payload])
end

while !sock.closed? && !sock.eof?
  data = sock.read_nonblock(1024)
  # puts "Received bytes: #{data.unpack("H*").first}"

  begin
    conn << data
  rescue StandardError => e
    puts "#{e.class} exception: #{e.message} - closing socket."
    e.backtrace.each { |l| puts "\t" + l }
    sock.close
  end
end
