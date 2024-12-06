require 'helper'

RSpec.describe HTTP2::Connection do
  include FrameHelpers
  before(:each) do
    @conn = Client.new
  end

  let(:f) { Framer.new }

  context 'initialization and settings' do
    it 'should raise error if first frame is not settings' do
      (frame_types - [settings_frame]).each do |frame|
        expect { @conn << frame }.to raise_error(ProtocolError)
        expect(@conn).to be_closed
      end
    end

    it 'should not raise error if first frame is SETTINGS' do
      expect { @conn << f.generate(settings_frame) }.to_not raise_error
      expect(@conn.state).to eq :connected
      expect(@conn).to_not be_closed
    end

    it 'should raise error if SETTINGS stream != 0' do
      frame = set_stream_id(f.generate(settings_frame), 0x1)
      expect { @conn << frame }.to raise_error(ProtocolError)
    end
  end

  context 'settings synchronization' do
    it 'should reflect outgoing settings when ack is received' do
      expect(@conn.local_settings[:settings_header_table_size]).to eq 4096
      @conn.settings(settings_header_table_size: 256)
      expect(@conn.local_settings[:settings_header_table_size]).to eq 4096

      ack = { type: :settings, stream: 0, payload: [], flags: [:ack] }
      @conn << f.generate(ack)

      expect(@conn.local_settings[:settings_header_table_size]).to eq 256
    end

    it 'should reflect incoming settings when SETTINGS is received' do
      expect(@conn.remote_settings[:settings_header_table_size]).to eq 4096
      settings = settings_frame
      settings[:payload] = [[:settings_header_table_size, 256]]

      @conn << f.generate(settings)

      expect(@conn.remote_settings[:settings_header_table_size]).to eq 256
    end

    it 'should reflect settings_max_frame_size recevied from peer' do
      settings = settings_frame
      settings[:payload] = [[:settings_max_frame_size, 16_385]]

      @conn << f.generate(settings)

      frame = {
        length: 16_385,
        type: :data,
        flags: [:end_stream],
        stream: 1,
        payload: 'a' * 16_385,
      }
      expect { @conn.send(frame) }.not_to raise_error(CompressionError)
    end

    it 'should send SETTINGS ACK when SETTINGS is received' do
      settings = settings_frame
      settings[:payload] = [[:settings_header_table_size, 256]]

      # We should expect two frames here (append .twice) - one for the connection setup, and one for the settings ack.
      frames = []
      expect(@conn).to receive(:send).twice do |frame|
        frames << frame
      end

      @conn.send_connection_preface
      @conn << f.generate(settings)

      frame = frames.last
      expect(frame[:type]).to eq :settings
      expect(frame[:flags]).to eq [:ack]
      expect(frame[:payload]).to eq []
    end
  end

  context 'stream management' do
    it 'should initialize to default stream limit (100)' do
      expect(@conn.local_settings[:settings_max_concurrent_streams]).to eq 100
    end

    it 'should change stream limit to received SETTINGS value' do
      @conn << f.generate(settings_frame)
      expect(@conn.remote_settings[:settings_max_concurrent_streams]).to eq 10
    end

    it 'should count open streams against stream limit' do
      s = @conn.new_stream
      expect(@conn.active_stream_count).to eq 0
      s.receive headers_frame
      expect(@conn.active_stream_count).to eq 1
    end

    it 'should not count reserved streams against stream limit' do
      s1 = @conn.new_stream
      s1.receive push_promise_frame
      expect(@conn.active_stream_count).to eq 0

      s2 = @conn.new_stream
      s2.send push_promise_frame
      expect(@conn.active_stream_count).to eq 0

      # transition to half closed
      s1.receive headers_frame
      s2.send headers_frame
      expect(@conn.active_stream_count).to eq 2

      # transition to closed
      s1.receive data_frame
      s2.send data_frame
      expect(@conn.active_stream_count).to eq 0

      expect(s1).to be_closed
      expect(s2).to be_closed
    end

    it 'should not exceed stream limit set by peer' do
      @conn << f.generate(settings_frame)

      expect do
        10.times do
          s = @conn.new_stream
          s.send headers_frame
        end
      end.to_not raise_error

      expect { @conn.new_stream }.to raise_error(StreamLimitExceeded)
    end

    it 'should initialize stream with HEADERS priority value' do
      @conn << f.generate(settings_frame)

      stream, headers = nil, headers_frame
      headers[:weight] = 20
      headers[:stream_dependency] = 0
      headers[:exclusive] = false

      @conn.on(:stream) { |s| stream = s }
      @conn << f.generate(headers)

      expect(stream.weight).to eq 20
    end

    it 'should initialize idle stream on PRIORITY frame' do
      @conn << f.generate(settings_frame)

      stream = nil
      @conn.on(:stream) { |s| stream = s }
      @conn << f.generate(priority_frame)

      expect(stream.state).to eq :idle
    end
  end

  context 'cleanup_recently_closed' do
    it 'should cleanup old connections' do
      now_ts = Time.now.to_i
      stream_ids = Array.new(4) { @conn.new_stream.id }
      expect(@conn.instance_variable_get('@streams').size).to eq(4)

      # Assume that the first 3 streams were closed in different time
      recently_closed = stream_ids[0, 3].zip([now_ts - 100, now_ts - 50, now_ts - 5]).to_h
      @conn.instance_variable_set('@streams_recently_closed', recently_closed)

      # Cleanup should delete streams that were closed earlier than 15s ago
      @conn.__send__(:cleanup_recently_closed)
      expect(@conn.instance_variable_get('@streams').size).to eq(2)
      expect(@conn.instance_variable_get('@streams_recently_closed')).to eq(stream_ids[2] => now_ts - 5)
    end
  end

  context 'Headers pre/post processing' do
    it 'should not concatenate multiple occurences of a header field with the same name' do
      input = [
        ['Content-Type', 'text/html'],
        ['Cache-Control', 'max-age=60, private'],
        ['Cache-Control', 'must-revalidate'],
      ]
      expected = [
        ['content-type', 'text/html'],
        ['cache-control', 'max-age=60, private'],
        ['cache-control', 'must-revalidate'],
      ]
      headers = []
      @conn.on(:frame) do |bytes|
        headers << f.parse(bytes) if [1, 5, 9].include?(bytes[3].ord)
      end

      stream = @conn.new_stream
      stream.headers(input)

      expect(headers.size).to eq 1
      emitted = Decompressor.new.decode(headers.first[:payload])
      expect(emitted).to match_array(expected)
    end

    it 'should not split zero-concatenated header field values' do
      input = [*RESPONSE_HEADERS,
               ['cache-control', "max-age=60, private\0must-revalidate"],
               ['content-type', 'text/html'],
               ['cookie', "a=b\0c=d; e=f"]]
      expected = [*RESPONSE_HEADERS,
                  ['cache-control', "max-age=60, private\0must-revalidate"],
                  ['content-type', 'text/html'],
                  ['cookie', "a=b\0c=d; e=f"]]

      result = nil
      @conn.on(:stream) do |stream|
        stream.on(:headers) { |h| result = h }
      end

      srv = Server.new
      srv.on(:frame) { |bytes| @conn << bytes }
      stream = srv.new_stream
      stream.headers(input)

      expect(result).to eq expected
    end
  end

  context 'flow control' do
    it 'should initialize to default flow window' do
      expect(@conn.remote_window).to eq DEFAULT_FLOW_WINDOW
    end

    it 'should update connection and stream windows on SETTINGS' do
      settings, data = settings_frame, data_frame
      settings[:payload] = [[:settings_initial_window_size, 1024]]
      data[:payload] = 'x' * 2048

      stream = @conn.new_stream

      stream.send headers_frame
      stream.send data
      expect(stream.remote_window).to eq(DEFAULT_FLOW_WINDOW - 2048)
      expect(@conn.remote_window).to eq(DEFAULT_FLOW_WINDOW - 2048)

      @conn << f.generate(settings)
      expect(@conn.remote_window).to eq(-1024)
      expect(stream.remote_window).to eq(-1024)
    end

    it 'should initialize streams with window specified by peer' do
      settings = settings_frame
      settings[:payload] = [[:settings_initial_window_size, 1024]]

      @conn << f.generate(settings)
      expect(@conn.new_stream.remote_window).to eq 1024
    end

    it 'should observe connection flow control' do
      settings, data = settings_frame, data_frame
      settings[:payload] = [[:settings_initial_window_size, 1000]]

      @conn << f.generate(settings)
      s1 = @conn.new_stream
      s2 = @conn.new_stream

      s1.send headers_frame
      s1.send data.merge(payload: 'x' * 900)
      expect(@conn.remote_window).to eq 100

      s2.send headers_frame
      s2.send data.merge(payload: 'x' * 200)
      expect(@conn.remote_window).to eq 0
      expect(@conn.buffered_amount).to eq 100

      @conn << f.generate(window_update_frame.merge(stream: 0, increment: 1000))
      expect(@conn.buffered_amount).to eq 0
      expect(@conn.remote_window).to eq 900
    end

    it 'should update window when data received is over half of the maximum local window size' do
      settings, data = settings_frame, data_frame
      conn = Client.new(settings_initial_window_size: 500)

      conn.receive f.generate(settings)
      s1 = conn.new_stream
      s2 = conn.new_stream

      s1.send headers_frame
      s2.send headers_frame
      expect(conn).to receive(:send) do |frame|
        expect(frame[:type]).to eq :window_update
        expect(frame[:stream]).to eq 0
        expect(frame[:increment]).to eq 400
      end
      conn.receive f.generate(data.merge(payload: 'x' * 200, end_stream: false, stream: s1.id))
      conn.receive f.generate(data.merge(payload: 'x' * 200, end_stream: false, stream: s2.id))
      expect(s1.local_window).to eq 300
      expect(s2.local_window).to eq 300
      expect(conn.local_window).to eq 500
    end
  end

  context 'framing' do
    it 'should buffer incomplete frames' do
      settings = settings_frame
      settings[:payload] = [[:settings_initial_window_size, 1000]]
      @conn << f.generate(settings)

      frame = f.generate(window_update_frame.merge(stream: 0, increment: 1000))
      @conn << frame
      expect(@conn.remote_window).to eq 2000

      @conn << frame.slice!(0, 1)
      @conn << frame
      expect(@conn.remote_window).to eq 3000
    end

    it 'should decompress header blocks regardless of stream state' do
      req_headers = [
        ['content-length', '20'],
        ['x-my-header', 'first'],
      ]

      cc = Compressor.new
      headers = headers_frame
      headers[:payload] = cc.encode(req_headers)

      @conn << f.generate(settings_frame)
      @conn.on(:stream) do |stream|
        expect(stream).to receive(:<<) do |frame|
          expect(frame[:payload]).to eq req_headers
        end
      end

      @conn << f.generate(headers)
    end

    it 'should decode non-contiguous header blocks' do
      req_headers = [
        ['content-length', '15'],
        ['x-my-header', 'first'],
      ]

      cc = Compressor.new
      h1, h2 = headers_frame, continuation_frame

      # Header block fragment might not complete for decompression
      payload = cc.encode(req_headers)
      h1[:payload] = payload.slice!(0, payload.size / 2) # first half
      h1[:stream] = 5
      h1[:flags] = []

      h2[:payload] = payload # the remaining
      h2[:stream] = 5

      @conn << f.generate(settings_frame)
      @conn.on(:stream) do |stream|
        expect(stream).to receive(:<<) do |frame|
          expect(frame[:payload]).to eq req_headers
        end
      end

      @conn << f.generate(h1)
      @conn << f.generate(h2)
    end

    it 'should require that split header blocks are a contiguous sequence' do
      headers = headers_frame
      headers[:flags] = []

      @conn << f.generate(settings_frame)
      @conn << f.generate(headers)
      (frame_types - [continuation_frame]).each do |frame|
        expect { @conn << f.generate(frame.deep_dup) }.to raise_error(ProtocolError)
      end
    end

    it 'should raise compression error on encode of invalid frame' do
      @conn << f.generate(settings_frame)
      stream = @conn.new_stream

      expect do
        stream.headers({ 'name' => Float::INFINITY })
      end.to raise_error(CompressionError)
    end

    it 'should raise connection error on decode of invalid frame' do
      @conn << f.generate(settings_frame)
      frame = f.generate(data_frame) # Receiving DATA on unopened stream 1 is an error.
      # Connection errors emit protocol error frames
      expect { @conn << frame }.to raise_error(ProtocolError)
    end

    it 'should emit encoded frames via on(:frame)' do
      bytes = nil
      @conn.on(:frame) { |d| bytes = d }
      @conn.settings(settings_max_concurrent_streams: 10,
                     settings_initial_window_size: 0x7fffffff)

      expect(bytes).to eq f.generate(settings_frame)
    end

    it 'should compress stream headers' do
      @conn.on(:frame) do |bytes|
        expect(bytes).not_to include('get')
        expect(bytes).not_to include('http')
        expect(bytes).not_to include('www.example.org') # should be huffman encoded
      end

      stream = @conn.new_stream
      stream.headers({ ':method' => 'get',
                       ':scheme' => 'http',
                       ':authority' => 'www.example.org',
                       ':path'   => '/resource' })
    end

    it 'should generate CONTINUATION if HEADERS is too long' do
      headers = []
      @conn.on(:frame) do |bytes|
        # bytes[3]: frame's type field
        headers << f.parse(bytes) if [1, 5, 9].include?(bytes[3].ord)
      end

      stream = @conn.new_stream
      stream.headers({
        ':method' => 'get',
        ':scheme' => 'http',
        ':authority' => 'www.example.org',
        ':path'   => '/resource',
        'custom' => 'q' * 44_000,
      }, end_stream: true)
      expect(headers.size).to eq 3
      expect(headers[0][:type]).to eq :headers
      expect(headers[1][:type]).to eq :continuation
      expect(headers[2][:type]).to eq :continuation
      expect(headers[0][:flags]).to eq [:end_stream]
      expect(headers[1][:flags]).to eq []
      expect(headers[2][:flags]).to eq [:end_headers]
    end

    it 'should not generate CONTINUATION if HEADERS fits exactly in a frame' do
      headers = []
      @conn.on(:frame) do |bytes|
        # bytes[3]: frame's type field
        headers << f.parse(bytes) if [1, 5, 9].include?(bytes[3].ord)
      end

      stream = @conn.new_stream
      stream.headers({
        ':method' => 'get',
        ':scheme' => 'http',
        ':authority' => 'www.example.org',
        ':path'   => '/resource',
        'custom' => 'q' * 18_682, # this number should be updated when Huffman table is changed
      }, end_stream: true)
      expect(headers[0][:length]).to eq @conn.remote_settings[:settings_max_frame_size]
      expect(headers.size).to eq 1
      expect(headers[0][:type]).to eq :headers
      expect(headers[0][:flags]).to include(:end_headers)
      expect(headers[0][:flags]).to include(:end_stream)
    end

    it 'should not generate CONTINUATION if HEADERS fits exactly in a frame' do
      headers = []
      @conn.on(:frame) do |bytes|
        # bytes[3]: frame's type field
        headers << f.parse(bytes) if [1, 5, 9].include?(bytes[3].ord)
      end

      stream = @conn.new_stream
      stream.headers({
        ':method' => 'get',
        ':scheme' => 'http',
        ':authority' => 'www.example.org',
        ':path'   => '/resource',
        'custom' => 'q' * 18_682, # this number should be updated when Huffman table is changed
      }, end_stream: true)
      expect(headers[0][:length]).to eq @conn.remote_settings[:settings_max_frame_size]
      expect(headers.size).to eq 1
      expect(headers[0][:type]).to eq :headers
      expect(headers[0][:flags]).to include(:end_headers)
      expect(headers[0][:flags]).to include(:end_stream)
    end

    it 'should generate CONTINUATION if HEADERS exceed the max payload by one byte' do
      headers = []
      @conn.on(:frame) do |bytes|
        headers << f.parse(bytes) if [1, 5, 9].include?(bytes[3].ord)
      end

      stream = @conn.new_stream
      stream.headers({
        ':method' => 'get',
        ':scheme' => 'http',
        ':authority' => 'www.example.org',
        ':path'   => '/resource',
        'custom' => 'q' * 18_683, # this number should be updated when Huffman table is changed
      }, end_stream: true)
      expect(headers[0][:length]).to eq @conn.remote_settings[:settings_max_frame_size]
      expect(headers[1][:length]).to eq 1
      expect(headers.size).to eq 2
      expect(headers[0][:type]).to eq :headers
      expect(headers[1][:type]).to eq :continuation
      expect(headers[0][:flags]).to eq [:end_stream]
      expect(headers[1][:flags]).to eq [:end_headers]
    end
  end

  context 'connection management' do
    it 'should raise error on invalid connection header' do
      srv = Server.new
      expect { srv << f.generate(settings_frame) }.to raise_error(HandshakeError)

      srv = Server.new
      expect do
        srv << CONNECTION_PREFACE_MAGIC
        srv << f.generate(settings_frame)
      end.to_not raise_error
    end

    it 'should respond to PING frames' do
      @conn << f.generate(settings_frame)
      expect(@conn).to receive(:send) do |frame|
        expect(frame[:type]).to eq :ping
        expect(frame[:flags]).to eq [:ack]
        expect(frame[:payload]).to eq '12345678'
      end

      @conn << f.generate(ping_frame)
    end

    it 'should fire callback on PONG' do
      @conn << f.generate(settings_frame)

      pong = nil
      @conn.ping('12345678') { |d| pong = d }
      @conn << f.generate(pong_frame)
      expect(pong).to eq '12345678'
    end

    it 'should fire callback on receipt of GOAWAY' do
      last_stream, payload, error = nil
      @conn << f.generate(settings_frame)
      @conn.on(:goaway) do |s, e, p|
        last_stream = s
        error = e
        payload = p
      end
      @conn << f.generate(goaway_frame.merge(last_stream: 17, payload: 'test'))

      expect(last_stream).to eq 17
      expect(error).to eq :no_error
      expect(payload).to eq 'test'

      expect(@conn).to be_closed
    end

    it 'should raise error when opening new stream after sending GOAWAY' do
      @conn.goaway
      expect(@conn).to be_closed

      expect { @conn.new_stream }.to raise_error(ConnectionClosed)
    end

    it 'should raise error when opening new stream after receiving GOAWAY' do
      @conn << f.generate(settings_frame)
      @conn << f.generate(goaway_frame)
      expect { @conn.new_stream }.to raise_error(ConnectionClosed)
    end

    it 'should not raise error when receiving connection management frames immediately after emitting goaway' do
      @conn.goaway
      expect(@conn).to be_closed

      expect { @conn << f.generate(settings_frame) }.not_to raise_error(ProtocolError)
      expect { @conn << f.generate(ping_frame) }.not_to raise_error(ProtocolError)
      expect { @conn << f.generate(goaway_frame) }.not_to raise_error(ProtocolError)
    end

    it 'should process connection management frames after GOAWAY' do
      @conn << f.generate(settings_frame)
      @conn << f.generate(headers_frame)
      @conn << f.generate(goaway_frame)
      @conn << f.generate(headers_frame.merge(stream: 7))
      @conn << f.generate(push_promise_frame)

      expect(@conn.active_stream_count).to eq 1
    end

    it 'should raise error on frame for invalid stream ID' do
      @conn << f.generate(settings_frame)

      expect do
        @conn << f.generate(data_frame.merge(stream: 31))
      end.to raise_error(ProtocolError)
    end

    it 'should not raise an error on frame for a closed stream ID' do
      srv = Server.new
      srv << CONNECTION_PREFACE_MAGIC

      stream = srv.new_stream
      stream.send headers_frame
      stream.send data_frame
      stream.close

      expect do
        srv << f.generate(rst_stream_frame.merge(stream: stream.id))
      end.to_not raise_error
    end

    it 'should send GOAWAY frame on connection error' do
      stream = @conn.new_stream

      expect(@conn).to receive(:encode) do |frame|
        expect(frame[:type]).to eq :settings
        [frame]
      end
      expect(@conn).to receive(:encode) do |frame|
        expect(frame[:type]).to eq :goaway
        expect(frame[:last_stream]).to eq stream.id
        expect(frame[:error]).to eq :protocol_error
        [frame]
      end

      expect { @conn << f.generate(data_frame) }.to raise_error(ProtocolError)
    end
  end

  context 'API' do
    it '.settings should emit SETTINGS frames' do
      expect(@conn).to receive(:send) do |frame|
        expect(frame[:type]).to eq :settings
        expect(frame[:payload]).to eq([
          [:settings_max_concurrent_streams, 10],
          [:settings_initial_window_size, 0x7fffffff],
        ])
        expect(frame[:stream]).to eq 0
      end

      @conn.settings(settings_max_concurrent_streams: 10,
                     settings_initial_window_size: 0x7fffffff)
    end

    it '.ping should generate PING frames' do
      expect(@conn).to receive(:send) do |frame|
        expect(frame[:type]).to eq :ping
        expect(frame[:payload]).to eq 'somedata'
      end

      @conn.ping('somedata')
    end

    it '.goaway should generate GOAWAY frame with last processed stream ID' do
      @conn << f.generate(settings_frame)
      @conn << f.generate(headers_frame.merge(stream: 17))

      expect(@conn).to receive(:send) do |frame|
        expect(frame[:type]).to eq :goaway
        expect(frame[:last_stream]).to eq 17
        expect(frame[:error]).to eq :internal_error
        expect(frame[:payload]).to eq 'payload'
      end

      @conn.goaway(:internal_error, 'payload')
    end
    it '.window_update should emit WINDOW_UPDATE frames' do
      expect(@conn).to receive(:send) do |frame|
        expect(frame[:type]).to eq :window_update
        expect(frame[:increment]).to eq 20
        expect(frame[:stream]).to eq 0
      end
      @conn.window_update(20)
    end
  end
end
