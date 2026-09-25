require "rails_helper"
require Rails.root.join("lib/betterstack/request_context")

RSpec.describe Betterstack::RequestContext do
  def context_during(env)
    seen = nil
    described_class.new(->(_) { seen = Logtail::CurrentContext.instance.snapshot }).call(env)
    seen[:http]
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
end
