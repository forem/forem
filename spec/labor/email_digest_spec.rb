require "rails_helper"

RSpec.describe EmailDigest, type: :labor do
  let(:user) { create(:user, email_digest_periodic: true) }
  let(:author) { create(:user) }

  let(:mailer) { double }
  let(:message_delivery) { double }

  before do
    allow(DigestMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:digest_email).and_return(message_delivery)
    allow(message_delivery).to receive(:deliver_now)
  end

  describe "::send_digest_email" do
    context "when there's article to be sent" do
      before { user.follow(author) }

      it "send digest email when there are at least 3 hot articles" do
        articles = create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)

        described_class.send_periodic_digest_email

        expect(DigestMailer).to have_received(:with).with(user: user, articles: articles)
        expect(mailer).to have_received(:digest_email)
        expect(message_delivery).to have_received(:deliver_now)
      end
    end
  end
end
