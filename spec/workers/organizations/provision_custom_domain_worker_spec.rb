require "rails_helper"

RSpec.describe Organizations::ProvisionCustomDomainWorker, type: :worker do
  let(:organization) { create(:organization, custom_domain: "blog.example.com") }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
  end

  it "creates a subscription and enqueues verification" do
    allow(FastlyTls::Client).to receive(:create_subscription).and_return("subs_123")
    
    expect {
      described_class.new.perform(organization.id)
    }.to change(Organizations::VerifyCustomDomainWorker.jobs, :size).by(1)

    organization.reload
    expect(organization.tls_subscription_id).to eq("subs_123")
    expect(organization.tls_status).to eq("pending")
    expect(FastlyTls::Client).to have_received(:create_subscription).with("blog.example.com")
  end

  it "does nothing if fastly api key is blank" do
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("")
    allow(FastlyTls::Client).to receive(:create_subscription)

    described_class.new.perform(organization.id)
    expect(FastlyTls::Client).not_to have_received(:create_subscription)
  end

  it "does nothing if tls_subscription_id is already present" do
    organization.update_columns(tls_subscription_id: "subs_existing")
    allow(FastlyTls::Client).to receive(:create_subscription)

    described_class.new.perform(organization.id)
    expect(FastlyTls::Client).not_to have_received(:create_subscription)
  end
end
