require "rails_helper"
require Rails.root.join("lib/betterstack/request_context")

RSpec.describe Betterstack::RequestContext do
  def full_context_during(env, &block)
    seen = nil
    app = lambda do |request_env|
      block&.call(request_env)
      seen = Logtail::CurrentContext.instance.snapshot
    end
    described_class.new(app).call(env)
    seen
  end

  def context_during(env)
    full_context_during(env)[:http]
  end

  let(:env) do
    Rack::MockRequest.env_for("https://dev.to/some/path", "REMOTE_ADDR" => "167.82.161.32",
                                                          "action_dispatch.request_id" => "req-1")
  end

  it "adds the request to the log context while the request runs" do
    expect(context_during(env)).to include(host: "dev.to", method: "GET", path: "/some/path", request_id: "req-1")
    expect(Logtail::CurrentContext.instance.snapshot).not_to have_key(:http)
  end

  it "uses Fastly's client IP, like the rest of Forem" do
    env["HTTP_FASTLY_CLIENT_IP"] = "198.51.100.23"

    expect(context_during(env)).to include(remote_addr: "198.51.100.23")
  end

  it "falls back to Rails' remote_ip" do
    expect(context_during(env)).to include(remote_addr: "167.82.161.32")
  end

  describe "lazy user context" do
    it "does not call Warden::Proxy#user when the user has not been loaded into @users" do
      warden = Warden::Proxy.new(env, Warden::Manager.new(->(_) { [200, {}, []] }))
      allow(warden).to receive(:user)
      env["warden"] = warden

      snapshot = full_context_during(env)

      expect(warden).not_to have_received(:user)
      expect(snapshot).not_to have_key(:user)
      expect(Logtail::CurrentContext.instance.snapshot).not_to have_key(:user)
    end

    it "extracts the user id when Warden has already loaded @users[:user] during the request" do
      warden = Warden::Proxy.new(env, Warden::Manager.new(->(_) { [200, {}, []] }))
      user = instance_double(User, id: 42)
      env["warden"] = warden

      snapshot = full_context_during(env) do
        warden.instance_variable_get(:@users)[:user] = user
      end

      expect(snapshot[:user]).to eq(id: 42)
      expect(Logtail::CurrentContext.instance.snapshot).not_to have_key(:user)
    end

    it "extracts the user id from an already-loaded rack.session without querying the database" do
      session = instance_double(ActionDispatch::Request::Session, loaded?: true)
      allow(session).to receive(:[]).with("warden.user.user.key").and_return([[99], "salt"])
      env["rack.session"] = session

      snapshot = full_context_during(env)

      expect(snapshot[:user]).to eq(id: 99)
    end

    it "does not force-load an unloaded ActionDispatch::Request::Session" do
      session = instance_double(ActionDispatch::Request::Session, loaded?: false)
      allow(session).to receive(:[])
      env["rack.session"] = session

      snapshot = full_context_during(env)

      expect(session).not_to have_received(:[])
      expect(snapshot).not_to have_key(:user)
    end

    it "extracts the user id from controller @validated_session_user_id or @current_user" do
      controller = Object.new
      controller.instance_variable_set(:@validated_session_user_id, 77)
      env["action_controller.instance"] = controller

      expect(full_context_during(env)[:user]).to eq(id: 77)
    end
  end
end
