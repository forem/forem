require "rails_helper"

RSpec.describe "MLH OmniAuth setup" do # rubocop:disable RSpec/DescribeClass
  let(:app) { ->(_env) { [200, {}, ["OK"]] } }
  let(:strategy) { OmniAuth::Strategies::MLH.new(app, "client-id", "client-secret") }

  before do
    MLH_OMNIAUTH_SETUP.call("omniauth.strategy" => strategy)
  end

  context "with local Core endpoints" do
    around do |example|
      original_oauth = ENV.fetch("MLH_OAUTH_BASE_URL", nil)
      original_api = ENV.fetch("MLH_API_BASE_URL", nil)
      ENV["MLH_OAUTH_BASE_URL"] = "https://core.example/"
      ENV["MLH_API_BASE_URL"] = "https://api.core.example/"
      example.run
    ensure
      ENV["MLH_OAUTH_BASE_URL"] = original_oauth
      ENV["MLH_API_BASE_URL"] = original_api
    end

    it "uses Core endpoints, limited scopes, and no persisted credentials", :aggregate_failures do
      expect(strategy.options.client_options.site).to eq("https://core.example")
      expect(strategy.options.client_options.authorize_url).to eq("https://core.example/oauth/authorize")
      expect(strategy.options.client_options.token_url).to eq("https://core.example/oauth/token")
      expect(strategy.options.client_options.api_site).to eq("https://api.core.example")
      expect(strategy.options.scope.split).to contain_exactly("public", "user:read:profile", "mlh:read:user")
      expect(strategy.options.persist_credentials).to be(false)
    end
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
end
