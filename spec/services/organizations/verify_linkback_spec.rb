require "rails_helper"

RSpec.describe Organizations::VerifyLinkback, type: :service do
  let(:organization) { create(:organization, url: "https://example.com", slug: "myorg") }

  # SafeHttp resolves each host before fetching; pin the public test hosts so
  # these examples don't depend on live DNS.
  before do
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    %w[example.com blog.example.com].each do |host|
      allow(Addrinfo).to receive(:getaddrinfo)
        .with(host, nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])
    end
  end

  describe ".call" do
    context "when verification_url is blank" do
      it "returns failure" do
        organization.update_column(:verification_url, nil)
        result = described_class.call(organization)
        expect(result.success?).to be false
        expect(result.error).to include("No verification URL")
      end
    end

    context "when organization has no website URL" do
      it "returns failure" do
        organization.update_columns(url: nil, verification_url: "https://example.com/about")
        result = described_class.call(organization)
        expect(result.success?).to be false
        expect(result.error).to include("no website URL")
      end
    end

    context "when verification URL is on a different domain" do
      it "returns failure" do
        organization.update_column(:verification_url, "https://other-domain.com/about")
        result = described_class.call(organization)
        expect(result.success?).to be false
        expect(result.error).to include("same domain")
      end
    end

    context "when verification URL is unreachable" do
      before do
        organization.update_column(:verification_url, "https://example.com/about")
        stub_request(:get, "https://example.com/about")
          .to_return(status: 404, body: "Not Found")
      end

      it "returns failure" do
        result = described_class.call(organization)
        expect(result.success?).to be false
        expect(result.error).to include("Could not reach")
      end
    end

    context "when the page has no link back to the org" do
      before do
        organization.update_column(:verification_url, "https://example.com/about")
        html = "<html><body><a href='https://unrelated.com'>Click here</a></body></html>"
        stub_request(:get, "https://example.com/about")
          .to_return(status: 200, body: html)
      end

      it "returns failure" do
        result = described_class.call(organization)
        expect(result.success?).to be false
        expect(result.error).to include("No link to your organization page")
      end
    end

    context "when the page has a valid link back to the org" do
      before do
        organization.update_column(:verification_url, "https://example.com/about")
        forem_url = URL.url
        html = "<html><body><a href='#{forem_url}/myorg'>Our community</a></body></html>"
        stub_request(:get, "https://example.com/about")
          .to_return(status: 200, body: html)
      end

      it "returns success and marks the org as verified with baseline_score" do
        result = described_class.call(organization)
        expect(result.success?).to be true
        expect(organization.reload.verified?).to be true
        expect(organization.verified_at).to be_present
        expect(organization.baseline_score).to eq(Settings::UserExperience.index_minimum_score.to_i)
      end
    end

    context "when the page has a link using just the path" do
      before do
        organization.update_column(:verification_url, "https://example.com/about")
        html = "<html><body><a href='/myorg'>Our community</a></body></html>"
        stub_request(:get, "https://example.com/about")
          .to_return(status: 200, body: html)
      end

      it "returns success" do
        result = described_class.call(organization)
        expect(result.success?).to be true
      end
    end

    context "when verification URL is a subdomain of the website" do
      before do
        organization.update_columns(url: "https://example.com", verification_url: "https://blog.example.com/about")
        forem_url = URL.url
        html = "<html><body><a href='#{forem_url}/myorg'>Community</a></body></html>"
        stub_request(:get, "https://blog.example.com/about")
          .to_return(status: 200, body: html)
      end

      it "allows subdomain verification" do
        result = described_class.call(organization)
        expect(result.success?).to be true
      end
    end

    context "when a network error occurs" do
      before do
        organization.update_column(:verification_url, "https://example.com/about")
        stub_request(:get, "https://example.com/about")
          .to_raise(Net::OpenTimeout.new("connection timed out"))
      end

      it "returns failure with connection error" do
        result = described_class.call(organization)
        expect(result.success?).to be false
        expect(result.error).to include("Could not connect")
      end
    end

    describe "non-public destinations" do
      it "blocks a verification URL pointing to a private or link-local IP" do
        internal_url = "http://169.254.169.254/latest/meta-data/"
        organization.update_columns(url: "http://169.254.169.254", verification_url: internal_url)
        stub_request(:get, internal_url).to_return(status: 200, body: "ami-id")

        result = described_class.call(organization)

        expect(result.success?).to be false
        expect(result.error).to eq("Verification URL is not allowed")
        expect(a_request(:get, internal_url)).not_to have_been_made
      end

      it "blocks a verification URL whose hostname resolves to a private IP" do
        allow(Addrinfo).to receive(:getaddrinfo)
          .with("internal.example", nil, nil, :STREAM)
          .and_return([instance_double(Addrinfo, ip_address: "10.0.0.5")])
        organization.update_columns(url: "https://internal.example", verification_url: "https://internal.example/about")
        stub_request(:get, "https://internal.example/about").to_return(status: 403, body: "Forbidden")

        result = described_class.call(organization)

        expect(result.success?).to be false
        expect(result.error).to eq("Verification URL is not allowed")
        expect(a_request(:get, "https://internal.example/about")).not_to have_been_made
      end

      it "does not follow a redirect to a private address or report its status" do
        internal_url = "http://169.254.169.254/latest/meta-data/"
        organization.update_column(:verification_url, "https://example.com/about")
        stub_request(:get, "https://example.com/about")
          .to_return(status: 302, headers: { "Location" => internal_url })
        stub_request(:get, internal_url).to_return(status: 404, body: "Not Found")

        result = described_class.call(organization)

        expect(result.success?).to be false
        expect(result.error).to eq("Verification URL is not allowed")
        expect(a_request(:get, internal_url)).not_to have_been_made
      end

      it "returns failure when redirects exceed the limit" do
        organization.update_column(:verification_url, "https://example.com/about")
        stub_request(:get, "https://example.com/about")
          .to_return(status: 302, headers: { "Location" => "https://example.com/about" })

        result = described_class.call(organization)

        expect(result.success?).to be false
        expect(result.error).to include("too many redirects")
      end
    end
  end
end
