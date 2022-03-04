require "rails_helper"

RSpec.describe Emails::SendUserDigestWorker, type: :worker do
  let(:worker) { subject }
  let(:user) do
    u = create(:user)
    u.notification_setting.update(email_digest_periodic: true)
    u
  end
  let(:author) { create(:user) }
  let(:mailer) { double }
  let(:message_delivery) { double }

  before do
    allow(DigestMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:digest_email).and_return(message_delivery)
    allow(message_delivery).to receive(:deliver_now)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "perform" do
    context "when there's articles to be sent" do
      before { user.follow(author) }

      it "send digest email when there are at least 3 hot articles" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)

        worker.perform(user.id)

        expect(DigestMailer).to have_received(:with).with(user: user, articles: Array)
        expect(mailer).to have_received(:digest_email)
        expect(message_delivery).to have_received(:deliver_now)
      end

      it "does not send email when user does not have email_digest_periodic" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)
        user.notification_setting.update_column(:email_digest_periodic, false)
        worker.perform(user.id)

        expect(DigestMailer).not_to have_received(:with)
      end

      it "does not send email when user is not registered" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)
        user.update_column(:registered, false)
        worker.perform(user.id)

        expect(DigestMailer).not_to have_received(:with)
      end
    end
  end
end
