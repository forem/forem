require "rails_helper"

RSpec.describe Organizations::VerifyCustomDomainWorker, type: :worker do
  let(:organization) { create(:organization, custom_domain: "blog.example.com", tls_subscription_id: "subs_123", tls_status: "pending") }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
  end

  it "updates status to issued if fastly returns issued" do
    allow(FastlyTls::Client).to receive(:get_subscription).and_return({ "attributes" => { "state" => "issued" } })
    
    described_class.new.perform(organization.id)
    expect(organization.reload.tls_status).to eq("issued")
  end

  it "re-enqueues if status is pending" do
    allow(FastlyTls::Client).to receive(:get_subscription).and_return({ "attributes" => { "state" => "pending" } })
    
    expect {
      described_class.new.perform(organization.id)
    }.to change(Organizations::VerifyCustomDomainWorker.jobs, :size).by(1)

    expect(organization.reload.tls_status).to eq("pending")
  end

  it "marks as failed and clears subscription_id if deleted upstream (404 error returned as nil)" do
    allow(FastlyTls::Client).to receive(:get_subscription).and_return(nil)
    
    described_class.new.perform(organization.id)
    organization.reload
    expect(organization.tls_status).to eq("failed")
    expect(organization.tls_subscription_id).to be_nil
  end
end
