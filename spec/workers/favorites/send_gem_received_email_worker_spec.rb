require "rails_helper"

RSpec.describe Favorites::SendGemReceivedEmailWorker, type: :worker do
  let(:worker) { subject }
  let(:author) { create(:user) }
  let(:leader) { create(:user, :community_leader_level_1) }
  let(:article) { create(:article, user: author) }
  let(:mailer) { instance_double(NotifyMailer) }
  let(:message_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

  include_examples "#enqueues_on_correct_queue", "low_priority", ["Article", 456]

  describe "#perform" do
    before do
      article.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current)
      allow(NotifyMailer).to receive(:with).and_return(mailer)
      allow(mailer).to receive(:gem_received_email).and_return(message_delivery)
    end

    it "emails the author of a gemmed article" do
      worker.perform("Article", article.id)

      expect(NotifyMailer).to have_received(:with).with(favoritable: article)
      expect(message_delivery).to have_received(:deliver_now)
    end

    it "emails the author of a gemmed comment" do
      comment = create(:comment, commentable: article, user: author)
      comment.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current)

      worker.perform("Comment", comment.id)

      expect(NotifyMailer).to have_received(:with).with(favoritable: comment)
    end

    it "does not email an author who turned off badge emails" do
      author.notification_setting.update!(email_badge_notifications: false)

      worker.perform("Article", article.id)

      expect(NotifyMailer).not_to have_received(:with)
    end

    it "does not email when the record is no longer a gem" do
      article.update_columns(favorited_by_user_id: nil)

      worker.perform("Article", article.id)

      expect(NotifyMailer).not_to have_received(:with)
    end

    it "ignores unknown types and missing records" do
      worker.perform("User", author.id)
      worker.perform("Article", 0)

      expect(NotifyMailer).not_to have_received(:with)
    end
  end
end
