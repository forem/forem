require "rails_helper"

RSpec.describe "HealthCheckUp" do
  describe "GET /up" do
    it "returns 200 OK without authentication or Subforem database lookups" do
      allow(Subforem).to receive(:cached_default_id)

      get "/up"

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("no-store")
      expect(Subforem).not_to have_received(:cached_default_id)
    end

    it "succeeds on HEAD /up" do
      head "/up"

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end

    it "reserves 'up' in ReservedWords and maps rails_health_check_path" do
      expect(rails_health_check_path).to eq("/up")
      expect(ReservedWords.all).to include("up")
    end
  end

  describe "production SSL and HostAuthorization exemptions" do
    let(:inner_app) { ->(_env) { [200, {}, ["OK"]] } }
    let(:probe_exclude) { ->(request) { (request.get? || request.head?) && request.path == "/up" } }
    let(:stack) do
      ssl_app = ActionDispatch::SSL.new(
        inner_app,
        hsts: { subdomains: true },
        redirect: { exclude: probe_exclude },
      )
      ActionDispatch::HostAuthorization.new(
        ssl_app,
        ["app.example.com"],
        exclude: probe_exclude,
      )
    end

    it "allows GET and HEAD /up over plain HTTP even from an unlisted host", :aggregate_failures do
      get_status, = stack.call(
        Rack::MockRequest.env_for("http://10.0.0.5/up", :method => "GET", "HTTP_HOST" => "10.0.0.5"),
      )
      head_status, = stack.call(
        Rack::MockRequest.env_for("http://10.0.0.5/up", :method => "HEAD", "HTTP_HOST" => "10.0.0.5"),
      )

      expect(get_status).to eq(200)
      expect(head_status).to eq(200)
    end

    it "does not exempt POST /up or other HTTP paths from HostAuthorization and SSL redirects", :aggregate_failures do
      post_up_status, = stack.call(
        Rack::MockRequest.env_for("http://10.0.0.5/up", :method => "POST", "HTTP_HOST" => "10.0.0.5"),
      )
      other_host_status, = stack.call(
        Rack::MockRequest.env_for("http://10.0.0.5/articles", :method => "GET", "HTTP_HOST" => "10.0.0.5"),
      )
      allowed_http_status, headers, = stack.call(
        Rack::MockRequest.env_for(
          "http://app.example.com/articles",
          :method => "GET",
          "HTTP_HOST" => "app.example.com",
        ),
      )

      expect(post_up_status).to eq(403)
      expect(other_host_status).to eq(403)
      expect(allowed_http_status).to eq(301)
      expect(headers["Location"]).to eq("https://app.example.com/articles")
    end
  end
end
