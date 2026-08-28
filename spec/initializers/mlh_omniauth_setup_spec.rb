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
end
