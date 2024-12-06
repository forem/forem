require 'helper'

RSpec.describe HTTP2::Server do
  include FrameHelpers
  before(:each) do
    @srv = Server.new
  end

  let(:f) { Framer.new }

  context 'initialization and settings' do
    it 'should return even stream IDs' do
      expect(@srv.new_stream.id).to be_even
    end

    it 'should emit SETTINGS on new connection' do
      frames = []
      @srv.on(:frame) { |recv| frames << recv }
      @srv << CONNECTION_PREFACE_MAGIC

      expect(f.parse(frames[0])[:type]).to eq :settings
    end

    it 'should initialize client with custom connection settings' do
      frames = []

      @srv = Server.new(settings_max_concurrent_streams: 200,
                        settings_initial_window_size:    2**10)
      @srv.on(:frame) { |recv| frames << recv }
      @srv << CONNECTION_PREFACE_MAGIC

      frame = f.parse(frames[0])
      expect(frame[:type]).to eq :settings
      expect(frame[:payload]).to include([:settings_max_concurrent_streams, 200])
      expect(frame[:payload]).to include([:settings_initial_window_size, 2**10])
    end
  end

  it 'should allow server push' do
    client = Client.new
    client.on(:frame) { |bytes| @srv << bytes }

    @srv.on(:stream) do |stream|
      expect do
        stream.promise({ ':method' => 'GET' }) {}
      end.to_not raise_error
    end

    client.new_stream
    client.send headers_frame
  end
end
