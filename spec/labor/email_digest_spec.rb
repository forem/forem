require "rails_helper"

class FakeDelegator < ActionMailer::MessageDelivery
  # TODO: we should replace all usage of .deliver to .deliver_now
  def deliver(*args)
    super
  end
end

RSpec.describe EmailDigest do
  let(:user) { create(:user, email_digest_periodic: true) }
  let(:author) { create(:user) }
  let(:mock_delegator) { instance_double("FakeDelegator") }

  before do
    allow(DigestMailer).to receive(:digest_email) { mock_delegator }
    allow(mock_delegator).to receive(:deliver).and_return(true)
    user
  end

  describe "::send_digest_email" do
    context "when there's article to be sent" do
      before { user.follow(author) }

      it "send digest email when there's atleast 3 hot articles" do
        create_list(:article, 3, user_id: author.id, positive_reactions_count: 20, score: 20)
        described_class.send_periodic_digest_email
        expect(DigestMailer).to have_received(:digest_email).with(
          user, [instance_of(Article), instance_of(Article), instance_of(Article)]
        )
      end
    end
  end
end
