require 'unit_spec_helper'

describe Rpush::Daemon::Apnsp8::Delivery do
  subject(:delivery) { described_class.new(app, http2_client, token_provider, batch) }

  let(:app) { double(bundle_id: 'MY BUNDLE ID') }
  let(:notification1) { double('Notification 1', data: {}, as_json: {}).as_null_object }
  let(:notification2) { double('Notification 2', data: {}, as_json: {}).as_null_object }

  let(:token_provider) { double(token: 'MY JWT TOKEN') }
  let(:max_concurrent_streams) { 100 }
  let(:remote_settings) { { settings_max_concurrent_streams: max_concurrent_streams } }
  let(:http_request) { double(on: nil) }
  let(:http2_client) do
    double(
      stream_count: 0,
      call_async: nil,
      join: nil,
      prepare_request: http_request,
      remote_settings: remote_settings
    )
  end

  let(:batch) { double(mark_delivered: nil, all_processed: nil) }
  let(:logger) { double(info: nil) }

  before do
    allow(batch).to receive(:each_notification) do |&blk|
      [notification1, notification2].each(&blk)
    end
    allow(Rpush).to receive_messages(logger: logger)
  end

  describe '#perform' do
    context 'with an HTTP2 client where max concurrent streams is not set' do
      let(:max_concurrent_streams) { 0x7fffffff }

      it 'does not fall into an infinite loop on notifications after the first' do
        start = Time.now
        thread = Thread.new { delivery.perform }

        loop do
          break unless thread.alive?

          if Time.now - start > 0.5
            thread.kill
            fail 'Stuck in an infinite loop'
          end
        end
      end
    end
  end
end
