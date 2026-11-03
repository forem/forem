require "rails_helper"

RSpec.describe "Rack::HostRedirect monkey patch" do # rubocop:disable RSpec/DescribeClass
  let(:inner_app) { ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] } }
  let(:middleware) { Rack::HostRedirect.new(inner_app, "practicaldev.herokuapp.com" => "dev.to") }

  def rack_env_for(host:, path:, query: "", scheme: "https")
    {
      "rack.url_scheme" => scheme,
      "HTTP_HOST" => host,
      "SERVER_NAME" => host,
      "SERVER_PORT" => scheme == "https" ? "443" : "80",
      "PATH_INFO" => path,
      "QUERY_STRING" => query
    }
  end

  it "redirects standard URLs on the mapped host with a 301" do
    env = rack_env_for(host: "practicaldev.herokuapp.com", path: "/talha666tahir", query: "page=2")

    status, headers, _body = middleware.call(env)

    expect(status).to eq(301)
    expect(headers["Location"]).to eq("https://dev.to/talha666tahir?page=2")
  end

  it "passes through requests on unmapped hosts without redirecting" do
    env = rack_env_for(host: "dev.to", path: "/talha666tahir/assets/[name]-[hash].js")

    status, _headers, body = middleware.call(env)

    expect(status).to eq(200)
    expect(body).to eq(["OK"])
  end

  it "percent-encodes brackets and unencoded characters instead of raising URI::InvalidURIError" do
    env = rack_env_for(
      host: "practicaldev.herokuapp.com",
      path: "/talha666tahir/assets/[name]-[hash].js",
    )

    status, headers, _body = middleware.call(env)

    expect(status).to eq(301)
    expect(headers["Location"]).to eq("https://dev.to/talha666tahir/assets/%5Bname%5D-%5Bhash%5D.js")
  end

  it "handles malformed markdown/JS fragments in the path without raising URI::InvalidURIError" do
    env = rack_env_for(
      host: "practicaldev.herokuapp.com",
      path: "/blog/polis-problem-[philosophy](https://iep.utm.edu/aristotle/)",
    )

    status, headers, _body = middleware.call(env)

    expect(status).to eq(301)
    expect(headers["Location"]).to eq("https://dev.to/blog/polis-problem-%5Bphilosophy%5D(https://iep.utm.edu/aristotle/)")
  end

  it "falls back to the root target URL when Addressable::URI cannot parse the URL" do
    allow(Addressable::URI).to receive(:parse).and_raise(
      Addressable::URI::InvalidURIError.new("invalid URI"),
    )
    env = rack_env_for(
      host: "practicaldev.herokuapp.com",
      path: "/talha666tahir/assets/[name]-[hash].js",
    )

    status, headers, _body = middleware.call(env)

    expect(status).to eq(301)
    expect(headers["Location"]).to eq("https://dev.to/")
  end
end
