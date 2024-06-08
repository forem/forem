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

        expect(DigestMailer).to have_received(:with).with(user: user, articles: Array, billboards: Array)
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

      it "includes billboards" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)
        bb_1 = create(:billboard, placement_area: "digest_first", published: true, approved: true)
        bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true)

        worker.perform(user.id)

        expect(DigestMailer).to have_received(:with) do |args|
          expect(args[:billboards]).to contain_exactly(bb_1, bb_2)
        end
      end

      it "creates billboard events when billboards are present" do
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)
        bb_1 = create(:billboard, placement_area: "digest_first", published: true, approved: true)
        bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true)

        worker.perform(user.id)

        expect(BillboardEvent.where(billboard_id: bb_1.id, category: "impression").size).to be(1)
        expect(BillboardEvent.where(billboard_id: bb_2.id, category: "impression").size).to be(1)
      end
    end
  end
end
