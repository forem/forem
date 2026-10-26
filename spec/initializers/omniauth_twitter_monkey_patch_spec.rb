require "rails_helper"

RSpec.describe "OmniAuth Twitter monkey patch" do # rubocop:disable RSpec/DescribeClass
  let(:inner_app) { ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] } }
  let(:strategy) { OmniAuth::Strategies::Twitter.new(inner_app, "consumer-key", "consumer-secret") }

  def rack_env_for(url, session_params: nil)
    env = Rack::MockRequest.env_for(url)
    env["rack.session"] = session_params ? { "omniauth.params" => session_params } : {}
    env["rack.session.options"] = {}
    env
  end

  describe "#callback_path" do
    it "returns the canonical Twitter callback path when omniauth.params is absent" do
      env = rack_env_for("https://dev.to/users/auth/twitter")
      strategy.instance_variable_set(:@env, env)

      expect(strategy.callback_path).to eq("/users/auth/twitter/callback")
    end

    it "does not raise URI::InvalidURIError when session['omniauth.params']['callback_url'] is a malformed URI" do
      env = rack_env_for(
        "https://dev.to/reactions",
        session_params: { "callback_url" => "p19IOADY' OR 751=(SELECT 751 FROM PG_SLEEP(15))--" },
      )
      strategy.instance_variable_set(:@env, env)

      expect(strategy.callback_path).to eq("/users/auth/twitter/callback")
    end

    it "does not raise ArgumentError when session['omniauth.params']['callback_url'] is a non-String" do
      env = rack_env_for(
        "https://dev.to/reactions",
        session_params: { "callback_url" => %w[not a string] },
      )
      strategy.instance_variable_set(:@env, env)

      expect(strategy.callback_path).to eq("/users/auth/twitter/callback")
    end

    it "ignores another provider's or arbitrary route's callback_url stored in session['omniauth.params']" do
      env = rack_env_for(
        "https://dev.to/users/auth/github/callback",
        session_params: { "callback_url" => "https://dev.to/users/auth/github/callback" },
      )
      strategy.instance_variable_set(:@env, env)

      expect(strategy.callback_path).to eq("/users/auth/twitter/callback")
    end
  end

  describe "#callback_url" do
    it "builds the base callback URL without appending request query parameters" do
      env = rack_env_for("https://dev.to/users/auth/twitter?secure_image_url=true&state=navbar_basic")
      strategy.instance_variable_set(:@env, env)

      expect(strategy.callback_url).to eq("#{URL.url}/users/auth/twitter/callback")
    end

    it "ignores an unvalidated callback_url query parameter on the request" do
      env = rack_env_for("https://dev.to/users/auth/twitter?callback_url=https://evil.example/steal&state=navbar_basic")
      strategy.instance_variable_set(:@env, env)

      expect(strategy.callback_url).to eq("#{URL.url}/users/auth/twitter/callback")
    end
  end

  describe "Rack middleware chain through Middlewares::SetCookieDomain" do
    let(:middleware_stack) { Middlewares::SetCookieDomain.new(strategy) }

    around do |example|
      original_test_mode = OmniAuth.config.test_mode
      OmniAuth.config.test_mode = false
      example.run
    ensure
      OmniAuth.config.test_mode = original_test_mode
    end

    it "passes unrelated requests through without raising when session has a SQLi/malformed callback_url" do
      env = rack_env_for(
        "https://dev.to/@@Ofp3u/infinity",
        session_params: { "callback_url" => "p19IOADY' OR 751=(SELECT 751 FROM PG_SLEEP(15))--" },
      )

      status, _headers, body = middleware_stack.call(env)

      expect(status).to eq(200)
      expect(body).to eq(["OK"])
    end

    it "does not hijack requests to paths matching session['omniauth.params']['callback_url']" do
      env = rack_env_for(
        "https://dev.to/reactions",
        session_params: { "callback_url" => "https://dev.to/reactions" },
      )

      status, _headers, body = middleware_stack.call(env)

      expect(status).to eq(200)
      expect(body).to eq(["OK"])
      expect(env["omniauth.strategy"]).to be_nil
    end
  end
end
