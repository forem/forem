require "rails_helper"

RSpec.describe "MLH OmniAuth setup" do # rubocop:disable RSpec/DescribeClass
  let(:app) { ->(_env) { [200, {}, ["OK"]] } }
  let(:strategy) { OmniAuth::Strategies::MLH.new(app, "client-id", "client-secret") }

  before do
    MLH_OMNIAUTH_SETUP.call("omniauth.strategy" => strategy)
  end

  it "keeps OAuth state verification enabled" do
    expect(strategy.options.provider_ignores_state).to be(false)
  end

  it "sends the state it records in the initiating session" do
    session = {}
    allow(strategy).to receive(:session).and_return(session)

    params = strategy.authorize_params

    expect(params[:state]).to be_present
    expect(session["omniauth.state"]).to eq(params[:state])
  end

  it "rejects a callback whose state does not match the initiating session" do
    request = instance_double(
      Rack::Request,
      params: { "code" => "authorization-code", "state" => "returned-state" },
    )
    allow(strategy).to receive_messages(
      request: request,
      session: { "omniauth.state" => "session-state" },
      fail!: nil,
      build_access_token: nil,
    )

    strategy.callback_phase

    expect(strategy).not_to have_received(:build_access_token)
    expect(strategy).to have_received(:fail!).with(
      :csrf_detected,
      instance_of(OmniAuth::Strategies::OAuth2::CallbackError),
    )
  end

  describe "local endpoint overrides" do
    around do |example|
      old_oauth = ENV["MLH_OAUTH_BASE_URL"]
      old_api = ENV["MLH_API_BASE_URL"]
      example.run
    ensure
      ENV["MLH_OAUTH_BASE_URL"] = old_oauth
      ENV["MLH_API_BASE_URL"] = old_api
    end

    let(:override_strategy) { OmniAuth::Strategies::MLH.new(app, "client-id", "client-secret") }

    it "points authorize, token and API origins at the configured local stack" do
      ENV["MLH_OAUTH_BASE_URL"] = "https://auth.mlh.test"
      ENV["MLH_API_BASE_URL"] = "https://api.mlh.test"

      MLH_OMNIAUTH_SETUP.call("omniauth.strategy" => override_strategy)

      client_options = override_strategy.options.client_options
      expect(client_options.site).to eq("https://auth.mlh.test")
      expect(client_options.authorize_url).to eq("https://auth.mlh.test/oauth/authorize")
      expect(client_options.token_url).to eq("https://auth.mlh.test/oauth/token")
      expect(client_options.api_site).to eq("https://api.mlh.test")
    end

    it "keeps production MyMLH endpoints when the env vars are blank" do
      ENV["MLH_OAUTH_BASE_URL"] = ""
      ENV["MLH_API_BASE_URL"] = ""

      MLH_OMNIAUTH_SETUP.call("omniauth.strategy" => override_strategy)

      client_options = override_strategy.options.client_options
      expect(client_options.site).to eq("https://www.mlh.com")
      expect(client_options.token_url).to eq("https://api.mlh.com/v4/oauth/token")
      expect(client_options.api_site).to eq("https://api.mlh.com")
    end
  end
end
