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
    end
  end
end

