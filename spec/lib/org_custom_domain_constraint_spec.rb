require "rails_helper"

RSpec.describe OrgCustomDomainConstraint do
  subject(:constraint) { described_class.new }

  let(:request) { instance_double(ActionDispatch::Request, host: host, env: env, path: "/", accept: "", headers: {}, params: {}, xhr?: false) }
  let(:env) { {} }
  let(:organization) { create(:organization, custom_domain: "custom.org") }

  before do
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
  end

  context "when host matches the app domain" do
    let(:host) { "forem.com" }

    it "returns false" do
      expect(constraint.matches?(request)).to be false
    end
  end

  context "when host is blank" do
    let(:host) { "" }

    it "returns false" do
      expect(constraint.matches?(request)).to be false
    end
  end

  context "when host does not match any organization custom domain" do
    let(:host) { "unknown.org" }

    it "returns false" do
      expect(constraint.matches?(request)).to be false
    end
  end

  context "when host matches an organization custom domain" do
    let(:host) { organization.custom_domain }

    context "when org_custom_domain feature flag is disabled" do
      before do
        FeatureFlag.disable(:org_custom_domain, FeatureFlag::Actor.new(organization))
      end

      it "returns false" do
        expect(constraint.matches?(request)).to be false
      end
    end

    context "when org_custom_domain feature flag is enabled" do
      before do
        FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
      end

      it "returns true and sets the organization in the env" do
        expect(constraint.matches?(request)).to be true
        expect(env["forem.custom_domain_org"]).to eq(organization)
      end

      it "returns true for article paths requested via fetch/preload (even with fetch headers or xhr)" do
        fetch_request = instance_double(
          ActionDispatch::Request,
          host: host,
          env: env,
          path: "/my-article-slug",
          accept: "*/*",
          headers: { "Sec-Fetch-Dest" => "empty", "Sec-Fetch-Mode" => "cors" },
          params: {},
          xhr?: false
        )
        expect(constraint.matches?(fetch_request)).to be true
      end

      it "returns false for platform async paths like /async_info" do
        async_request = instance_double(
          ActionDispatch::Request,
          host: host,
          env: env,
          path: "/async_info/article",
          accept: "application/json",
          headers: {},
          params: {},
          xhr?: false
        )
        expect(constraint.matches?(async_request)).to be false
      end

      it "returns false for platform paths like /reactions" do
        reactions_request = instance_double(
          ActionDispatch::Request,
          host: host,
          env: env,
          path: "/reactions",
          accept: "application/json",
          headers: {},
          params: {},
          xhr?: false
        )
        expect(constraint.matches?(reactions_request)).to be false
      end

      it "returns false for platform paths like /auth_pass" do
        auth_request = instance_double(
          ActionDispatch::Request,
          host: host,
          env: env,
          path: "/auth_pass/iframe",
          accept: "text/html",
          headers: {},
          params: {},
          xhr?: false
        )
        expect(constraint.matches?(auth_request)).to be false
      end
    end
  end
end
