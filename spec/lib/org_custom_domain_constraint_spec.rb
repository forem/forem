require "rails_helper"

RSpec.describe OrgCustomDomainConstraint do
  subject(:constraint) { described_class.new }

  let(:request) { instance_double(ActionDispatch::Request, host: host, env: env, path: "/", accept: "") }
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
    end
  end
end
