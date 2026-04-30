require "rails_helper"

RSpec.describe Organization, type: :model do
  let(:organization) { create(:organization) }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
  end

  describe "#manage_fastly_tls_subscription" do
    it "enqueues provisioning when custom_domain is added" do
      expect {
        organization.update!(custom_domain: "blog.example.com")
      }.to change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)
    end

    it "deletes old subscription when custom_domain is removed" do
      organization.update_columns(custom_domain: "old.example.com", tls_subscription_id: "subs_123", tls_status: "issued")
      allow(FastlyTls::Client).to receive(:delete_subscription)

      organization.update!(custom_domain: nil)
      
      expect(FastlyTls::Client).to have_received(:delete_subscription).with("subs_123")
      expect(organization.reload.tls_subscription_id).to be_nil
      expect(organization.reload.tls_status).to eq("not_started")
    end
  end
end
