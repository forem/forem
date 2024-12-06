require 'helper'

RSpec.describe HTTP2::Framer do
  let(:f) { Framer.new }

  context 'common header' do
    let(:frame) do
      {
        length: 4,
        type: :headers,
        flags: [:end_stream, :end_headers],
        stream: 15,
      }
    end

    let(:bytes) { [0, 0x04, 0x01, 0x5, 0x0000000F].pack('CnCCN') }

    it 'should generate common 9 byte header' do
      expect(f.common_header(frame)).to eq bytes
    end

    it 'should parse common 9 byte header' do
      expect(f.read_common_header(Buffer.new(bytes))).to eq frame
    end

    it 'should generate a large frame' do
      f = Framer.new
      f.max_frame_size = 2**24 - 1
      frame = {
        length: 2**18 + 2**16 + 17,
        type: :headers,
        flags: [:end_stream, :end_headers],
        stream: 15,
      }
      bytes = [5, 17, 0x01, 0x5, 0x0000000F].pack('CnCCN')
      expect(f.common_header(frame)).to eq bytes
      expect(f.read_common_header(Buffer.new(bytes))).to eq frame
    end

    it 'should raise exception on invalid frame type when sending' do
      expect do
        frame[:type] = :bogus
        f.common_header(frame)
      end.to raise_error(CompressionError, /invalid.*type/i)
    end

    it 'should raise exception on invalid stream ID' do
      expect do
        frame[:stream] = Framer::MAX_STREAM_ID + 1
        f.common_header(frame)
      end.to raise_error(CompressionError, /stream/i)
    end

    it 'should raise exception on invalid frame flag' do
      expect do
        frame[:flags] = [:bogus]
        f.common_header(frame)
      end.to raise_error(CompressionError, /frame flag/)
    end

    it 'should raise exception on invalid frame size' do
      expect do
        frame[:length] = 2**24
        f.common_header(frame)
      end.to raise_error(CompressionError, /too large/)
    end
  end

  context 'DATA' do
    it 'should generate and parse bytes' do
      frame = {
        length: 4,
        type: :data,
        flags: [:end_stream],
        stream: 1,
        payload: 'text',
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0x4, 0x0, 0x1, 0x1, *'text'.bytes].pack('CnCCNC*')

      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'HEADERS' do
    it 'should generate and parse bytes' do
      frame = {
        length: 12,
        type: :headers,
        flags: [:end_stream, :end_headers],
        stream: 1,
        payload: 'header-block',
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0xc, 0x1, 0x5, 0x1, *'header-block'.bytes].pack('CnCCNC*')
      expect(f.parse(bytes)).to eq frame
    end

    it 'should carry an optional stream priority' do
      frame = {
        length: 16,
        type: :headers,
        flags: [:end_headers],
        stream: 1,
        stream_dependency: 15,
        weight: 12,
        exclusive: false,
        payload: 'header-block',
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0x11, 0x1, 0x24, 0x1, 0xf, 0xb, *'header-block'.bytes].pack('CnCCNNCC*')
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'PRIORITY' do
    it 'should generate and parse bytes' do
      frame = {
        length: 5,
        type: :priority,
        stream: 1,
        stream_dependency: 15,
        weight: 12,
        exclusive: true,
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0x5, 0x2, 0x0, 0x1, 0x8000000f, 0xb].pack('CnCCNNC')
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'RST_STREAM' do
    it 'should generate and parse bytes' do
      frame = {
        length: 4,
        type: :rst_stream,
        stream: 1,
        error: :stream_closed,
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0x4, 0x3, 0x0, 0x1, 0x5].pack('CnCCNN')
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'SETTINGS' do
    let(:frame) do
      {
        type: :settings,
        flags: [],
        stream: 0,
        payload: [
          [:settings_max_concurrent_streams, 10],
          [:settings_header_table_size,      2048],
        ],
      }
    end

    it 'should generate and parse bytes' do
      bytes = f.generate(frame)
      expect(bytes).to eq [0, 12, 0x4, 0x0, 0x0, 3, 10, 1, 2048].pack('CnCCNnNnN')
      parsed = f.parse(bytes)
      parsed.delete(:length)
      frame.delete(:length)
      expect(parsed).to eq frame
    end

    it 'should generate settings when id is given as an integer' do
      frame[:payload][1][0] = 1
      bytes = f.generate(frame)
      expect(bytes).to eq [0, 12, 0x4, 0x0, 0x0, 3, 10, 1, 2048].pack('CnCCNnNnN')
    end

    it 'should ignore custom settings when sending' do
      frame[:payload] = [
        [:settings_max_concurrent_streams, 10],
        [:settings_initial_window_size,    20],
        [55, 30],
      ]

      buf = f.generate(frame)
      frame[:payload].slice!(2) # cut off the extension
      frame[:length] = 12       # frame length should be computed WITHOUT extensions
      expect(f.parse(buf)).to eq frame
    end

    it 'should ignore custom settings when receiving' do
      frame[:payload] = [
        [:settings_max_concurrent_streams, 10],
        [:settings_initial_window_size,    20],
      ]

      buf = f.generate(frame)
      buf.setbyte(2, 18) # add 6 to the frame length
      buf << "\x00\x37\x00\x00\x00\x1e"
      parsed = f.parse(buf)
      parsed.delete(:length)
      frame.delete(:length)
      expect(parsed).to eq frame
    end

    it 'should raise exception on sending invalid stream ID' do
      expect do
        frame[:stream] = 1
        f.generate(frame)
      end.to raise_error(CompressionError, /Invalid stream ID/)
    end

    it 'should raise exception on receiving invalid stream ID' do
      expect do
        buf = f.generate(frame)
        buf.setbyte(8, 1)
        f.parse(buf)
      end.to raise_error(ProtocolError, /Invalid stream ID/)
    end

    it 'should raise exception on sending invalid setting' do
      expect do
        frame[:payload] = [[:random, 23]]
        f.generate(frame)
      end.to raise_error(CompressionError, /Unknown settings ID/)
    end

    it 'should raise exception on receiving invalid payload length' do
      expect do
        buf = f.generate(frame)
        buf.setbyte(2, 11) # change payload length
        f.parse(buf)
      end.to raise_error(ProtocolError, /Invalid settings payload length/)
    end
  end

  context 'PUSH_PROMISE' do
    it 'should generate and parse bytes' do
      frame = {
        length: 11,
        type: :push_promise,
        flags: [:end_headers],
        stream: 1,
        promise_stream: 2,
        payload: 'headers',
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0xb, 0x5, 0x4, 0x1, 0x2, *'headers'.bytes].pack('CnCCNNC*')
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'PING' do
    let(:frame) do
      {
        length: 8,
        stream: 1,
        type: :ping,
        flags: [:ack],
        payload: '12345678',
      }
    end

    it 'should generate and parse bytes' do
      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0x8, 0x6, 0x1, 0x1, *'12345678'.bytes].pack('CnCCNC*')
      expect(f.parse(bytes)).to eq frame
    end

    it 'should raise exception on invalid payload' do
      expect do
        frame[:payload] = '1234'
        f.generate(frame)
      end.to raise_error(CompressionError, /Invalid payload size/)
    end
  end

  context 'GOAWAY' do
    let(:frame) do
      {
        length: 13,
        stream: 1,
        type: :goaway,
        last_stream: 2,
        error: :no_error,
        payload: 'debug',
      }
    end

    it 'should generate and parse bytes' do
      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0xd, 0x7, 0x0, 0x1, 0x2, 0x0, *'debug'.bytes].pack('CnCCNNNC*')
      expect(f.parse(bytes)).to eq frame
    end

    it 'should treat debug payload as optional' do
      frame.delete :payload
      frame[:length] = 0x8

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0x8, 0x7, 0x0, 0x1, 0x2, 0x0].pack('CnCCNNN')
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'WINDOW_UPDATE' do
    it 'should generate and parse bytes' do
      frame = {
        length: 4,
        type: :window_update,
        increment: 10,
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0x4, 0x8, 0x0, 0x0, 0xa].pack('CnCCNN')
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'CONTINUATION' do
    it 'should generate and parse bytes' do
      frame = {
        length: 12,
        type: :continuation,
        stream: 1,
        flags: [:end_headers],
        payload: 'header-block',
      }

      bytes = f.generate(frame)
      expect(bytes).to eq [0, 0xc, 0x9, 0x4, 0x1, *'header-block'.bytes].pack('CnCCNC*')
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'ALTSVC' do
    it 'should generate and parse bytes' do
      frame = {
        length: 44,
        type: :altsvc,
        stream: 1,
        max_age: 1_402_290_402,     # 4
        port: 8080,                 # 2
        proto: 'h2-13',             # 1 + 5
        host: 'www.example.com',    # 1 + 15
        origin: 'www.example.com',  # 15
      }
      bytes = f.generate(frame)
      expected = [0, 43, 0xa, 0, 1, 1_402_290_402, 8080].pack('CnCCNNn')
      expected << [5, *'h2-13'.bytes].pack('CC*')
      expected << [15, *'www.example.com'.bytes].pack('CC*')
      expected << [*'www.example.com'.bytes].pack('C*')
      expect(bytes).to eq expected
      expect(f.parse(bytes)).to eq frame
    end
  end

  context 'Padding' do
    [:data, :headers, :push_promise].each do |type|
      [1, 256].each do |padlen|
        context "generating #{type} frame padded #{padlen}" do
          before do
            @frame = {
              length: 12,
              type: type,
              stream: 1,
              payload: 'example data',
            }
            @frame[:promise_stream] = 2 if type == :push_promise
            @normal = f.generate(@frame)
            @padded = f.generate(@frame.merge(padding: padlen))
          end
          it 'should generate a frame with padding' do
            expect(@padded.bytesize).to eq @normal.bytesize + padlen
          end
          it 'should fill padded octets with zero' do
            trailer_len = padlen - 1
            expect(@padded[-trailer_len, trailer_len]).to match(/\A\0*\z/)
          end
          it 'should parse a frame with padding' do
            expect(f.parse(Buffer.new(@padded))).to eq \
              f.parse(Buffer.new(@normal)).merge(padding: padlen)
          end
          it 'should preserve payload' do
            expect(f.parse(Buffer.new(@padded))[:payload]).to eq @frame[:payload]
          end
        end
      end
    end
    context 'generating with invalid padding length' do
      before do
        @frame = {
          length: 12,
          type: :data,
          stream: 1,
          payload: 'example data',
        }
      end
      [0, 257, 1334].each do |padlen|
        it "should raise error on trying to generate data frame padded with invalid #{padlen}" do
          expect do
            f.generate(@frame.merge(padding: padlen))
          end.to raise_error(CompressionError, /padding/i)
        end
      end
      it 'should raise error when adding a padding would make frame too large' do
        @frame[:payload] = 'q' * (f.max_frame_size - 200)
        @frame[:length]  = @frame[:payload].size
        @frame[:padding] = 210 # would exceed 4096
        expect do
          f.generate(@frame)
        end.to raise_error(CompressionError, /padding/i)
      end
    end
    context 'parsing frames with invalid paddings' do
      before do
        @frame = {
          length: 12,
          type: :data,
          stream: 1,
          payload: 'example data',
        }
        @padlen = 123
        @padded = f.generate(@frame.merge(padding: @padlen))
      end
      it 'should raise exception when the given padding is longer than the payload' do
        @padded.setbyte(9, 240)
        expect { f.parse(Buffer.new(@padded)) }.to raise_error(ProtocolError, /padding/)
      end
    end
  end

  it 'should determine frame length' do
    frames = [
      [{ type: :data, stream: 1, flags: [:end_stream], payload: 'abc' }, 3],
      [{ type: :headers, stream: 1, payload: 'abc' }, 3],
      [{ type: :priority, stream: 3, stream_dependency: 30, exclusive: false, weight: 1 }, 5],
      [{ type: :rst_stream, stream: 3, error: 100 }, 4],
      [{ type: :settings, payload: [[:settings_max_concurrent_streams, 10]] }, 6],
      [{ type: :push_promise, promise_stream: 5, payload: 'abc' }, 7],
      [{ type: :ping, payload: 'blob' * 2 }, 8],
      [{ type: :goaway, last_stream: 5, error: 20, payload: 'blob' }, 12],
      [{ type: :window_update, stream: 1, increment: 1024 }, 4],
      [{ type: :continuation, stream: 1, payload: 'abc' }, 3],
    ]

    frames.each do |(frame, size)|
      bytes = f.generate(frame)
      expect(bytes.slice(1, 2).unpack('n').first).to eq size
      expect(bytes.readbyte(0)).to eq 0
    end
  end

  it 'should parse single frame at a time' do
    frames = [
      { type: :headers, stream: 1, payload: 'headers' },
      { type: :data, stream: 1, flags: [:end_stream], payload: 'abc' },
    ]

    buf = f.generate(frames[0]) << f.generate(frames[1])

    expect(f.parse(buf)).to eq frames[0]
    expect(f.parse(buf)).to eq frames[1]
  end

  it 'should process full frames only' do
    frame = { type: :headers, stream: 1, payload: 'headers' }
    bytes = f.generate(frame)

    expect(f.parse(bytes[0...-1])).to be_nil
    expect(f.parse(bytes)).to eq frame
    expect(bytes).to be_empty
  end

  it 'should ignore unknown extension frames' do
    frame = { type: :headers, stream: 1, payload: 'headers' }
    bytes = f.generate(frame)
    bytes = Buffer.new(bytes + bytes) # Two HEADERS frames in bytes
    bytes.setbyte(3, 42) # Make the first unknown type 42

    expect(f.parse(bytes)).to be_nil   # first frame should be ignored
    expect(f.parse(bytes)).to eq frame # should generate only one HEADERS
    expect(bytes).to be_empty
  end
end
