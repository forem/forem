require "rails_helper"

RSpec.describe Organization, type: :model do
  let(:organization) { create(:organization) }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
  end

  describe "callbacks" do
    it "registers manage_fastly_tls_subscription as an after commit callback" do
      callback_filters = described_class._commit_callbacks.select { |callback| callback.kind == :after }.map(&:filter)
      expect(callback_filters).to include(:manage_fastly_tls_subscription)
    end
  end

  describe "#manage_fastly_tls_subscription" do
    it "enqueues provisioning when custom_domain is added" do
      organization.custom_domain = "blog.example.com"
      allow(organization).to receive(:saved_change_to_custom_domain?).and_return(true)
      allow(organization).to receive(:saved_change_to_custom_domain).and_return([nil, "blog.example.com"])

      expect {
        organization.send(:manage_fastly_tls_subscription)
      }.to change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)
    end

    it "deletes old subscription when custom_domain is removed" do
      organization.update_columns(custom_domain: "old.example.com", tls_subscription_id: "subs_123", tls_status: "issued")
      organization.custom_domain = nil
      allow(organization).to receive(:saved_change_to_custom_domain?).and_return(true)
      allow(organization).to receive(:saved_change_to_custom_domain).and_return(["old.example.com", nil])

      expect {
        organization.send(:manage_fastly_tls_subscription)
      }.to change(Organizations::DeleteCustomDomainWorker.jobs, :size).by(1)
      
      expect(organization.reload.tls_subscription_id).to be_nil
      expect(organization.reload.tls_status).to eq("not_started")
    end
  end
end
