require 'helper'

RSpec.describe HTTP2::Client do
  include FrameHelpers
  before(:each) do
    @client = Client.new
  end

  let(:f) { Framer.new }

  context 'initialization and settings' do
    it 'should return odd stream IDs' do
      expect(@client.new_stream.id).not_to be_even
    end

    it 'should emit connection header and SETTINGS on new client connection' do
      frames = []
      @client.on(:frame) { |bytes| frames << bytes }
      @client.ping('12345678')

      expect(frames[0]).to eq CONNECTION_PREFACE_MAGIC
      expect(f.parse(frames[1])[:type]).to eq :settings
    end

    it 'should initialize client with custom connection settings' do
      frames = []

      @client = Client.new(settings_max_concurrent_streams: 200)
      @client.on(:frame) { |bytes| frames << bytes }
      @client.ping('12345678')

      frame = f.parse(frames[1])
      expect(frame[:type]).to eq :settings
      expect(frame[:payload]).to include([:settings_max_concurrent_streams, 200])
    end

    it 'should initialize client when receiving server settings before sending ack' do
      frames = []
      @client.on(:frame) { |bytes| frames << bytes }
      @client << f.generate(settings_frame)

      expect(frames[0]).to eq CONNECTION_PREFACE_MAGIC
      expect(f.parse(frames[1])[:type]).to eq :settings
      ack_frame = f.parse(frames[2])
      expect(ack_frame[:type]).to eq :settings
      expect(ack_frame[:flags]).to include(:ack)
    end
  end

  context 'upgrade' do
    it 'fails when client has already created streams' do
      @client.new_stream
      expect { @client.upgrade }.to raise_error(HTTP2::Error::ProtocolError)
    end

    it 'sends the preface' do
      expect(@client).to receive(:send_connection_preface)
      @client.upgrade
    end

    it 'initializes the first stream in the half-closed state' do
      stream = @client.upgrade
      expect(stream.state).to be(:half_closed_local)
    end
  end

  context 'push' do
    it 'should disallow client initiated push' do
      expect do
        @client.promise({}) {}
      end.to raise_error(NoMethodError)
    end

    it 'should raise error on PUSH_PROMISE against stream 0' do
      expect do
        @client << set_stream_id(f.generate(push_promise_frame), 0)
      end.to raise_error(ProtocolError)
    end

    it 'should raise error on PUSH_PROMISE against bogus stream' do
      expect do
        @client << set_stream_id(f.generate(push_promise_frame), 31_415)
      end.to raise_error(ProtocolError)
    end

    it 'should raise error on PUSH_PROMISE against non-idle stream' do
      expect do
        s = @client.new_stream
        s.send headers_frame

        @client << set_stream_id(f.generate(push_promise_frame), s.id)
        @client << set_stream_id(f.generate(push_promise_frame), s.id)
      end.to raise_error(ProtocolError)
    end

    it 'should emit stream object for received PUSH_PROMISE' do
      s = @client.new_stream
      s.send headers_frame

      promise = nil
      @client.on(:promise) { |stream| promise = stream }
      @client << set_stream_id(f.generate(push_promise_frame), s.id)

      expect(promise.id).to eq 2
      expect(promise.state).to eq :reserved_remote
    end

    it 'should emit promise headers for received PUSH_PROMISE' do
      header = nil
      s = @client.new_stream
      s.send headers_frame

      @client.on(:promise) do |stream|
        stream.on(:promise_headers) do |h|
          header = h
        end
      end
      @client << set_stream_id(f.generate(push_promise_frame), s.id)

      expect(header).to be_a(Array)
      # expect(header).to eq([%w(a b)])
    end

    it 'should auto RST_STREAM promises against locally-RST stream' do
      s = @client.new_stream
      s.send headers_frame
      s.close

      allow(@client).to receive(:send)
      expect(@client).to receive(:send) do |frame|
        expect(frame[:type]).to eq :rst_stream
        expect(frame[:stream]).to eq 2
      end

      @client << set_stream_id(f.generate(push_promise_frame), s.id)
    end
  end

  context 'alt-svc' do
    context 'received in the connection' do
      it 'should emit :altsvc when receiving one' do
        @client << f.generate(settings_frame)
        frame = nil
        @client.on(:altsvc) do |f|
          frame = f
        end
        @client << f.generate(altsvc_frame)
        expect(frame).to be_a(Hash)
      end
      it 'should not emit :altsvc when the frame when contains no host' do
        @client << f.generate(settings_frame)
        frame = nil
        @client.on(:altsvc) do |f|
          frame = f
        end

        @client << f.generate(altsvc_frame.merge(origin: nil))
        expect(frame).to be_nil
      end
    end
    context 'received in a stream' do
      it 'should emit :altsvc' do
        s = @client.new_stream
        s.send headers_frame
        s.close

        frame = nil
        s.on(:altsvc) { |f| frame = f }

        @client << set_stream_id(f.generate(altsvc_frame.merge(origin: nil)), s.id)

        expect(frame).to be_a(Hash)
      end
      it 'should not emit :alt_svc when the frame when contains a origin' do
        s = @client.new_stream
        s.send headers_frame
        s.close

        frame = nil
        s.on(:altsvc) { |f| frame = f }

        @client << set_stream_id(f.generate(altsvc_frame), s.id)

        expect(frame).to be_nil
      end
    end
  end
end
