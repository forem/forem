require "rails_helper"

RSpec.describe Settings::Authentication do
  describe "#acceptable_domain?" do
    subject { described_class.acceptable_domain?(domain: domain) }

    let(:domain) { "hello.com" }

    context "with blocked domain" do
      before do
        allow(described_class).to receive(:blocked_registration_email_domains).and_return([domain])
      end

      it { is_expected.to be_falsey }
    end

    context "when given a subdomain of a blocked domain" do
      subject { described_class.acceptable_domain?(domain: "world.#{domain}") }

      before { allow(described_class).to receive(:blocked_registration_email_domains).and_return([domain]) }

      it { is_expected.to be_falsey }
    end

    context "when the given domain has a suffix of the blocked domain" do
      subject { described_class.acceptable_domain?(domain: "world#{domain}") }

      before { allow(described_class).to receive(:blocked_registration_email_domains).and_return([domain]) }

      it { is_expected.to be_truthy }
    end

    context "with allowed domain" do
      before do
        allow(described_class).to receive(:allowed_registration_email_domains).and_return([domain])
      end

      it { is_expected.to be_truthy }
    end

    context "with no domains blocked nor explicitly allowed" do
      before do
        allow(described_class).to receive(:allowed_registration_email_domains).and_return([])
      end

      it { is_expected.to be_truthy }
    end

    context "with no domains blocked but an explicitly allowed domain" do
      before do
        allow(described_class).to receive(:allowed_registration_email_domains).and_return(["wonka.vision"])
      end

      it { is_expected.to be_falsey }
    end
  end

  describe "validations" do
    describe "#blocked_registration_email_domains" do
      it "allows valid domain lists" do
        expect do
          described_class.blocked_registration_email_domains = "example.com, example2.com"
        end.not_to raise_error
      end

      it "rejects invalid domain lists" do
        expect do
          described_class.blocked_registration_email_domains = "example.com, e.c"
        end.to raise_error(/must be a comma-separated list of valid domains/)
      end
    end

    describe "#allowed_registration_email_domains" do
      it "allows valid domain lists" do
        expect do
          described_class.allowed_registration_email_domains = "example.com, example2.com"
        end.not_to raise_error
      end

      it "rejects invalid domain lists" do
        expect do
          described_class.allowed_registration_email_domains = "example.com, e.c"
        end.to raise_error(/must be a comma-separated list of valid domains/)
      end
    end
  end
end
