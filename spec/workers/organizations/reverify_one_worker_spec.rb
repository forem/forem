require "rails_helper"

RSpec.describe Organizations::ReverifyOneWorker, type: :worker do
  describe "#perform" do
    let!(:organization) do
      org = create(:organization)
      org.update_columns(verified: true, verified_at: Time.current, verification_url: "https://example.com/about")
      org
    end

    it "keeps verification when linkback is found" do
      allow(Organizations::VerifyLinkback).to receive(:call)
        .and_return(Organizations::VerifyLinkback::Result.new("success?": true, error: nil))

      subject.perform(organization.id)
      expect(organization.reload.verified?).to be true
    end

    it "revokes verification when linkback is not found" do
      allow(Organizations::VerifyLinkback).to receive(:call)
        .and_return(Organizations::VerifyLinkback::Result.new("success?": false, error: "Not found"))

      subject.perform(organization.id)
      organization.reload
      expect(organization.verified?).to be false
      expect(organization.verified_at).to be_nil
    end

    it "enqueues a deverification notification when verification is revoked" do
      allow(Organizations::VerifyLinkback).to receive(:call)
        .and_return(Organizations::VerifyLinkback::Result.new("success?": false, error: "Not found"))
      allow(Notifications::OrganizationDeverificationWorker).to receive(:perform_async)

      subject.perform(organization.id)
      expect(Notifications::OrganizationDeverificationWorker).to have_received(:perform_async).with(organization.id)
    end

    it "does not send notification when verification passes" do
      allow(Organizations::VerifyLinkback).to receive(:call)
        .and_return(Organizations::VerifyLinkback::Result.new("success?": true, error: nil))
      allow(Notifications::OrganizationDeverificationWorker).to receive(:perform_async)

      subject.perform(organization.id)
      expect(Notifications::OrganizationDeverificationWorker).not_to have_received(:perform_async)
    end

    it "does nothing if organization is not found" do
      allow(Organizations::VerifyLinkback).to receive(:call)

      subject.perform(-1)
      expect(Organizations::VerifyLinkback).not_to have_received(:call)
    end

    it "does nothing if organization is no longer verified" do
      organization.update_columns(verified: false)
      allow(Organizations::VerifyLinkback).to receive(:call)

      subject.perform(organization.id)
      expect(Organizations::VerifyLinkback).not_to have_received(:call)
    end
  end
end
