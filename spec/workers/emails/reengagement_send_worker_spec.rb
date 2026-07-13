require "rails_helper"

RSpec.describe Emails::ReengagementSendWorker do
  let(:email) { create(:email, subject: "Stay?", body: "Hi *|name|* *|stay_subscribed_url|*") }
  let(:user)  { create(:user) }
  let!(:recipient) { EmailReengagementRecipient.create!(user: user, campaign_key: "c1") }

  it "enqueues a BatchCustomSendWorker with the campaign_key and stamps recipients" do
    allow(Emails::BatchCustomSendWorker).to receive(:perform_async)
    described_class.new.perform(email.id, "c1", [user.id])

    expect(Emails::BatchCustomSendWorker).to have_received(:perform_async)
      .with([user.id], email.subject, email.body, email.type_of, email.id, anything, "c1")
    expect(recipient.reload.sent_at).to be_present
    expect(recipient.reload.email_id).to eq(email.id)
  end
end
