require 'flipper/adapters/http'
require 'flipper/adapters/pstore'
require 'rack/handler/webrick'

FLIPPER_SPEC_API_PORT = ENV.fetch('FLIPPER_SPEC_API_PORT', 9001).to_i

RSpec.describe Flipper::Adapters::Http do
  context 'adapter' do
    subject do
      described_class.new(url: "http://localhost:#{FLIPPER_SPEC_API_PORT}")
    end

    before :all do
      dir = FlipperRoot.join('tmp').tap(&:mkpath)
      log_path = dir.join('flipper_adapters_http_spec.log')
      @pstore_file = dir.join('flipper.pstore')
      @pstore_file.unlink if @pstore_file.exist?

      api_adapter = Flipper::Adapters::PStore.new(@pstore_file)
      flipper_api = Flipper.new(api_adapter)
      app = Flipper::Api.app(flipper_api)
      server_options = {
        Port: FLIPPER_SPEC_API_PORT,
        StartCallback: -> { @started = true },
        Logger: WEBrick::Log.new(log_path.to_s, WEBrick::Log::INFO),
        AccessLog: [
          [log_path.open('w'), WEBrick::AccessLog::COMBINED_LOG_FORMAT],
        ],
      }
      @server = WEBrick::HTTPServer.new(server_options)
      @server.mount '/', Rack::Handler::WEBrick, app

      Thread.new { @server.start }
      Timeout.timeout(1) { :wait until @started }
    end

    after :all do
      @server.shutdown if @server
    end

    before(:each) do
      @pstore_file.unlink if @pstore_file.exist?
    end

    it_should_behave_like 'a flipper adapter'

    it "can enable and disable unregistered group" do
      flipper = Flipper.new(subject)
      expect(flipper[:search].enable_group(:some_made_up_group)).to be(true)
      expect(flipper[:search].groups_value).to eq(Set["some_made_up_group"])

      expect(flipper[:search].disable_group(:some_made_up_group)).to be(true)
      expect(flipper[:search].groups_value).to eq(Set.new)
    end
  end

  it "sends default headers" do
    headers = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'User-Agent' => "Flipper HTTP Adapter v#{Flipper::VERSION}",
    }
    stub_request(:get, "http://app.com/flipper/features/feature_panel")
      .with(headers: headers)
      .to_return(status: 404, body: "", headers: {})

    adapter = described_class.new(url: 'http://app.com/flipper')
    adapter.get(flipper[:feature_panel])
  end

  describe "#get" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features/feature_panel")
        .to_return(status: 503, body: "", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.get(flipper[:feature_panel])
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#get_multi" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features?keys=feature_panel")
        .to_return(status: 503, body: "", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.get_multi([flipper[:feature_panel]])
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#get_all" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features")
        .to_return(status: 503, body: "", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.get_all
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#features" do
    it "raises error when not successful response" do
      stub_request(:get, "http://app.com/flipper/features")
        .to_return(status: 503, body: "", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.features
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#add" do
    it "raises error when not successful" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.add(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#remove" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.remove(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#clear" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      expect {
        adapter.clear(Flipper::Feature.new(:search, adapter))
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe "#enable" do
    it "raises error when not successful" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(true)
      expect {
        adapter.enable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error, "Failed with status: 503")
    end

    it "doesn't raise json error if body cannot be parsed" do
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: "barf", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(true)
      expect {
        adapter.enable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error)
    end

    it "includes response information if available when raising error" do
      api_response = {
        "code" => "error",
        "message" => "This feature has reached the limit to the number of " +
                     "actors per feature. Check out groups as a more flexible " +
                     "way to enable many actors.",
        "more_info" => "https://www.flippercloud.io/docs",
      }
      stub_request(:post, /app.com/)
        .to_return(status: 503, body: JSON.dump(api_response), headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(true)
      error_message = "Failed with status: 503\n\nThis feature has reached the " +
                      "limit to the number of actors per feature. Check out " +
                      "groups as a more flexible way to enable many actors.\n" +
                      "https://www.flippercloud.io/docs"
      expect {
        adapter.enable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error, error_message)
    end
  end

  describe "#disable" do
    it "raises error when not successful" do
      stub_request(:delete, /app.com/)
        .to_return(status: 503, body: "{}", headers: {})

      adapter = described_class.new(url: 'http://app.com/flipper')
      feature = Flipper::Feature.new(:search, adapter)
      gate = feature.gate(:boolean)
      thing = gate.wrap(false)
      expect {
        adapter.disable(feature, gate, thing)
      }.to raise_error(Flipper::Adapters::Http::Error)
    end
  end

  describe 'configuration' do
    let(:debug_output) { object_double($stderr) }
    let(:options) do
      {
        url: 'http://app.com/mount-point',
        headers: { 'X-Custom-Header' => 'foo' },
        basic_auth_username: 'username',
        basic_auth_password: 'password',
        read_timeout: 100,
        open_timeout: 40,
        write_timeout: 40,
        debug_output: debug_output,
      }
    end
    subject { described_class.new(options) }
    let(:feature) { flipper[:feature_panel] }

    before do
      stub_request(:get, %r{\Ahttp://app.com*}).
        to_return(body: fixture_file('feature.json'))
    end

    it 'allows client to set request headers' do
      subject.get(feature)
      expect(
        a_request(:get, 'http://app.com/mount-point/features/feature_panel')
        .with(headers: { 'X-Custom-Header' => 'foo' })
      ).to have_been_made.once
    end

    it 'allows client to set basic auth' do
      subject.get(feature)
      expect(
        a_request(:get, 'http://app.com/mount-point/features/feature_panel')
        .with(basic_auth: %w(username password))
      ).to have_been_made.once
    end

    it 'allows client to set debug output' do
      user_agent = Net::HTTP.new("app.com")
      allow(Net::HTTP).to receive(:new).and_return(user_agent)

      expect(user_agent).to receive(:set_debug_output).with(debug_output)
      subject.get(feature)
    end
  end

  def fixture_file(name)
    fixtures_path = File.expand_path('../../../fixtures', __FILE__)
    File.new(fixtures_path + '/' + name)
  end
end
