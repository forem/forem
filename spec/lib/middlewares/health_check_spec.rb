require "rails_helper"

RSpec.describe Middlewares::HealthCheck, type: :middleware do
  let(:downstream_app) { instance_double(Proc) }
  let(:middleware) { described_class.new(downstream_app) }

  describe "#call" do
    it "returns 200 HTML with no-store Cache-Control on GET /up without calling downstream" do
      allow(downstream_app).to receive(:call)
      env = Rack::MockRequest.env_for("/up", method: "GET")

      status, headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to include("text/html")
      expect(headers["Cache-Control"]).to eq("no-store")
      expect(body.join).to include("green")
      expect(downstream_app).not_to have_received(:call)
    end

    it "returns 200 with an empty body on HEAD /up without calling downstream" do
      allow(downstream_app).to receive(:call)
      env = Rack::MockRequest.env_for("/up", method: "HEAD")

      status, headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(headers["Cache-Control"]).to eq("no-store")
      expect(body).to eq([])
      expect(downstream_app).not_to have_received(:call)
    end

    it "delegates non-GET/HEAD requests on /up to downstream" do
      expected = [404, {}, ["Not Found"]]
      allow(downstream_app).to receive(:call).and_return(expected)
      env = Rack::MockRequest.env_for("/up", method: "POST")

      expect(middleware.call(env)).to eq(expected)
      expect(downstream_app).to have_received(:call).with(env)
    end

    it "delegates other paths to downstream" do
      expected = [200, {}, ["OK"]]
      allow(downstream_app).to receive(:call).and_return(expected)
      env = Rack::MockRequest.env_for("/articles", method: "GET")

      expect(middleware.call(env)).to eq(expected)
      expect(downstream_app).to have_received(:call).with(env)
    end
  end
end
