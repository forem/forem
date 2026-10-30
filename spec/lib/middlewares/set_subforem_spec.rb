require "rails_helper"

RSpec.describe Middlewares::SetSubforem do
  let(:app) { double("app", call: [200, {}, ["OK"]]) }
  let(:middleware) { described_class.new(app) }

  before do
    # Clear RequestStore before each test
    RequestStore.clear!
  end

  after do
    RequestStore.clear!
  end

  describe "#call" do
    context "when a subforem exists for the requested domain" do
      let!(:subforem) { create(:subforem, domain: "community.example.com") }
      let!(:default_subforem) { create(:subforem) }
      let(:env) do
        Rack::MockRequest.env_for("https://community.example.com/articles")
      end

      before do
        allow(Subforem).to receive(:cached_id_by_domain).with("community.example.com").and_return(subforem.id)
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
        allow(Subforem).to receive(:cached_root_id).and_return(nil)
        allow(Subforem).to receive(:cached_root_domain).and_return(nil)
        allow(Subforem).to receive(:cached_default_domain).and_return(default_subforem.domain)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({
          subforem.id => "community.example.com",
          default_subforem.id => default_subforem.domain
        })
        allow(Subforem).to receive(:cached_all_domains).and_return([subforem.domain, default_subforem.domain])
      end

      it "sets subforem_id in RequestStore" do
        middleware.call(env)
        expect(RequestStore.store[:subforem_id]).to eq(subforem.id)
      end

      it "sets subforem_domain in RequestStore from cached hash" do
        middleware.call(env)
        expect(RequestStore.store[:subforem_domain]).to eq("community.example.com")
      end

      it "sets default_subforem_id in RequestStore" do
        middleware.call(env)
        expect(RequestStore.store[:default_subforem_id]).to eq(default_subforem.id)
      end

      it "uses the cached id_to_domain_hash to set subforem_domain" do
        expect(Subforem).to receive(:cached_id_to_domain_hash).and_return({
          subforem.id => "community.example.com"
        })
        middleware.call(env)
        expect(RequestStore.store[:subforem_domain]).to eq("community.example.com")
      end
    end

    context "when no subforem matches the requested domain" do
      let!(:default_subforem) { create(:subforem) }
      let(:env) do
        Rack::MockRequest.env_for("https://unknown.example.com/articles")
      end

      before do
        allow(Subforem).to receive(:cached_id_by_domain).with("unknown.example.com").and_return(nil)
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
        allow(Subforem).to receive(:cached_root_id).and_return(nil)
        allow(Subforem).to receive(:cached_root_domain).and_return(nil)
        allow(Subforem).to receive(:cached_default_domain).and_return(default_subforem.domain)
        allow(Subforem).to receive(:cached_all_domains).and_return([default_subforem.domain])
      end

      it "sets subforem_id to nil" do
        middleware.call(env)
        expect(RequestStore.store[:subforem_id]).to be_nil
      end

      it "does not set subforem_domain in RequestStore" do
        middleware.call(env)
        expect(RequestStore.store[:subforem_domain]).to be_nil
      end

      it "still sets default_subforem_id" do
        middleware.call(env)
        expect(RequestStore.store[:default_subforem_id]).to eq(default_subforem.id)
      end
    end

    context "when passed_domain parameter is provided" do
      let!(:subforem) { create(:subforem, domain: "override.example.com") }
      let!(:default_subforem) { create(:subforem) }
      let(:env) do
        Rack::MockRequest.env_for("https://actual.example.com/articles?passed_domain=override.example.com")
      end

      before do
        allow(Subforem).to receive(:cached_id_by_domain).with("override.example.com").and_return(subforem.id)
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
        allow(Subforem).to receive(:cached_root_id).and_return(nil)
        allow(Subforem).to receive(:cached_root_domain).and_return(nil)
        allow(Subforem).to receive(:cached_default_domain).and_return(default_subforem.domain)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({
          subforem.id => "override.example.com",
          default_subforem.id => default_subforem.domain
        })
        allow(Subforem).to receive(:cached_all_domains).and_return([subforem.domain, default_subforem.domain])
      end

      it "uses the passed_domain parameter instead of the request host" do
        middleware.call(env)
        expect(RequestStore.store[:subforem_id]).to eq(subforem.id)
        expect(RequestStore.store[:subforem_domain]).to eq("override.example.com")
      end

      it "correctly parses and uses passed_domain when provided as a full URL" do
        url_env = Rack::MockRequest.env_for("https://actual.example.com/articles?passed_domain=https://override.example.com")
        middleware.call(url_env)
        expect(RequestStore.store[:subforem_id]).to eq(subforem.id)
        expect(RequestStore.store[:subforem_domain]).to eq("override.example.com")
      end
    end

    context "when the request host is a bare hostname or a subdomain" do
      before do
        allow(Subforem).to receive(:cached_id_by_domain).and_return(nil)
        allow(Subforem).to receive(:cached_id_by_domain).with("example.com").and_return(1)
        allow(Subforem).to receive(:cached_id_by_domain).with("community.example.com").and_return(2)
        allow(Subforem).to receive_messages(cached_default_id: 1, cached_root_id: nil, cached_root_domain: nil,
                                            cached_default_domain: "example.com",
                                            cached_id_to_domain_hash: { 1 => "example.com",
                                                                        2 => "community.example.com" },
                                            cached_all_domains: ["example.com", "community.example.com"])
        allow(Settings::General).to receive(:app_domain).and_return("example.com")
        allow(Rack::Utils).to receive(:delete_cookie_header!)
      end

      it "drops the port from a passed_domain before looking up the subforem" do
        middleware.call(Rack::MockRequest.env_for("https://example.com/?passed_domain=community.example.com:3000"))
        expect(RequestStore.store[:subforem_id]).to eq(2)
      end

      it "keeps the host from a passed_domain URL" do
        middleware.call(Rack::MockRequest.env_for("https://example.com/?passed_domain=http://community.example.com/x"))
        expect(RequestStore.store[:subforem_id]).to eq(2)
      end

      it "falls back to the request host when passed_domain is not valid UTF-8" do
        env = Rack::MockRequest.env_for("https://community.example.com/auth_pass/iframe?passed_domain=%C0%AF")
        expect { middleware.call(env) }.not_to raise_error
        expect(RequestStore.store[:subforem_id]).to eq(2)
      end

      it "removes the session cookies on a subdomain of the registrable domain" do
        allow(PublicSuffix).to receive(:parse)
        middleware.call(Rack::MockRequest.env_for("https://community.example.com/articles"))
        expect(PublicSuffix).not_to have_received(:parse)
        expect(Rack::Utils).to have_received(:delete_cookie_header!)
          .with(anything, "remember_user_token", domain: "community.example.com")
      end

      it "keeps the session cookies on the registrable domain itself" do
        allow(PublicSuffix).to receive(:parse)
        middleware.call(Rack::MockRequest.env_for("https://example.com/articles"))
        expect(PublicSuffix).not_to have_received(:parse)
        expect(RequestStore.store[:subforem_id]).to eq(1)
        expect(Rack::Utils).not_to have_received(:delete_cookie_header!)
      end

      it "logs an invalid domain and still normalizes frame headers when the host is localhost" do
        allow(app).to receive(:call).and_return([200, { "X-Frame-Options" => "SAMEORIGIN" }, ["OK"]])
        allow(Rails.logger).to receive(:error)
        allow(PublicSuffix).to receive(:parse)

        _status, headers, _body = middleware.call(
          Rack::MockRequest.env_for("http://localhost:3000/articles?passed_domain=example.com"),
        )

        expect(PublicSuffix).not_to have_received(:parse)
        expect(Rails.logger).to have_received(:error).with("Invalid domain: localhost")
        expect(Rack::Utils).not_to have_received(:delete_cookie_header!)
        expect(headers).not_to have_key("X-Frame-Options")
        expect(headers["Content-Security-Policy"]).to eq("frame-ancestors https://example.com https://community.example.com")
      end

      it "includes 'self' in frame-ancestors when running in development" do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(Rails.logger).to receive(:error)

        _status, headers, _body = middleware.call(
          Rack::MockRequest.env_for("http://localhost:3000/articles"),
        )

        expect(headers["Content-Security-Policy"]).to eq(
          "frame-ancestors 'self' https://example.com https://community.example.com",
        )
      end

      it "falls back to PublicSuffix.parse for hosts outside [A-Za-z0-9.-]" do
        allow(Subforem).to receive(:cached_id_by_domain).with("foo_bar.example.com").and_return(2)
        middleware.call(Rack::MockRequest.env_for("https://foo_bar.example.com/articles"))
        expect(Rack::Utils).to have_received(:delete_cookie_header!)
          .with(anything, "remember_user_token", domain: "foo_bar.example.com")
      end
    end

    context "when a request has an empty body and a multipart Content-Type header" do
      let(:env) do
        Rack::MockRequest.env_for(
          "https://actual.example.com/articles",
          "CONTENT_TYPE" => "multipart/form-data; boundary=----WebKitFormBoundaryE199uG4vT6",
          "CONTENT_LENGTH" => "100",
          :input => ""
        )
      end

      it "does not raise EOFError" do
        expect { middleware.call(env) }.not_to raise_error
      end

      it "does not include JQuery::FileUpload::Rails::Middleware in the Rails middleware stack" do
        expect(Rails.application.middleware.middlewares).not_to include(JQuery::FileUpload::Rails::Middleware)
      end
    end

    context "when chained before Middlewares::SetCookieDomain" do
      let!(:subforem) { create(:subforem, domain: "community.example.com") }
      let(:inner_app) { ->(_env) { [200, {}, ["OK"]] } }
      let(:cookie_middleware) { Middlewares::SetCookieDomain.new(inner_app) }
      let(:stacked_middleware) { described_class.new(cookie_middleware) }
      let(:env) do
        Rack::MockRequest.env_for("https://community.example.com/articles").merge(
          "rack.session.options" => {},
        )
      end

      before do
        allow(Subforem).to receive(:cached_id_by_domain).with("community.example.com").and_return(subforem.id)
        allow(Subforem).to receive_messages(
          cached_default_id: subforem.id,
          cached_root_id: subforem.id,
          cached_root_domain: "community.example.com",
          cached_default_domain: "community.example.com",
          cached_id_to_domain_hash: { subforem.id => "community.example.com" },
          cached_all_domains: ["community.example.com"],
        )
      end

      it "populates RequestStore[:subforem_id] before SetCookieDomain reads Settings::General.app_domain" do
        observed_subforem_id = nil
        allow(Settings::General).to receive(:app_domain) do
          observed_subforem_id ||= RequestStore.store[:subforem_id]
          "community.example.com"
        end

        stacked_middleware.call(env)

        expect(observed_subforem_id).to eq(subforem.id)
        expect(env["rack.session.options"][:domain]).to eq(".example.com")
      end
    end
  end
end
