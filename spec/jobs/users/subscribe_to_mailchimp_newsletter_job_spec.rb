require "rails_helper"

RSpec.describe Users::SubscribeToMailchimpNewsletterJob, type: :job do
  include_examples "#enqueues_job", "users_subscribe_to_mailchimp_newsletter", [1, 2]

  describe "#perform_now" do
    let(:user) { FactoryBot.create(:user) }

    it "subscribes user to mailchimp newsletter" do
      mailchimp_bot = double
      allow(MailchimpBot).to receive(:new).and_return(mailchimp_bot)
      allow(mailchimp_bot).to receive(:upsert)

      described_class.perform_now(user.id)

      expect(mailchimp_bot).to have_received(:upsert)
    end
  end
end
