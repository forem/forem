require "rails_helper"

RSpec.describe Notifications::CreateRoundRobinModerationNotificationsWorker do
  let(:comment) { create(:comment) }
  let(:article) { create(:article) }
  let!(:mod) { create(:user, :trusted) }
  let(:worker) { subject }

  def prepare_for_round_robin(user)
    last_moderation_time = Time.current - Notifications::Moderation::MODERATORS_AVAILABILITY_DELAY - 1.week
    user.update(last_moderation_notification: last_moderation_time, last_reacted_at: 2.days.ago)
    user.notification_setting.update(mod_roundrobin_notifications: true)
  end

  def check_received_call(notifiable_type = nil)
    worker.perform(id, notifiable_type)
    expect(Notifications::Moderation::Send).to have_received(:call)
  end

  def check_non_received_call(notifiable_type = nil)
    worker.perform(id, notifiable_type)
    expect(Notifications::Moderation::Send).not_to have_received(:call)
  end

  describe "#perform" do
    before do
      allow(Notifications::Moderation::Send).to receive(:call)
    end

    describe "When available moderator(s) + comment" do
      it "calls the service" do
        prepare_for_round_robin(mod)
        worker.perform(comment.id, "Comment")
        expect(Notifications::Moderation::Send).to have_received(:call)
      end
    end

    describe "when available moderator(s) + article" do
      it "calls the service" do
        prepare_for_round_robin(mod)
        worker.perform(article.id, "Article")
        expect(Notifications::Moderation::Send).to have_received(:call)
      end
    end

    describe "when no available moderator for comment" do
      it "does not call the service" do
        worker.perform(comment.id, "Comment")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when no available moderator for article" do
      it "does not call the service" do
        worker.perform(article.id, "Article")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when no valid comment or article" do
      it "does not call the service" do
        prepare_for_round_robin(mod)

        worker.perform(Article.maximum(:id).to_i + 1, "Article")
        expect(Notifications::Moderation::Send).not_to have_received(:call)

        worker.perform(Comment.maximum(:id).to_i + 1, "Comment")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when no valid comment/article + no moderator" do
      it "does not call the service" do
        worker.perform(Article.maximum(:id).to_i + 1, "Article")
        expect(Notifications::Moderation::Send).not_to have_received(:call)

        worker.perform(Comment.maximum(:id).to_i + 1, "Comment")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when the notifiable user is limited" do
      let(:user) { create(:user, :limited) }
      let(:article) { create(:article, user: user) }
      let(:comment) { create(:comment, user: user) }

      it "does not call the send service" do
        worker.perform(article.id, "Comment")
        expect(Notifications::Moderation::Send).not_to have_received(:call)

        worker.perform(comment.id, "Comment")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when moderator is the comment author" do
      before do
        prepare_for_round_robin(mod)
      end

      it "does not call the service" do
        comment = create(:comment, user: mod, commentable: article)
        worker.perform(comment.id, "Comment")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when moderator is the article author" do
      before do
        prepare_for_round_robin(mod)
      end

      it "does not call the service" do
        article = create(:article, user: mod)
        worker.perform(article.id, "Article")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when the comment's commentable does not exist" do
      before do
        prepare_for_round_robin(mod)
        comment.commentable.destroy!
      end

      it "does not call the service" do
        worker.perform(comment.id, "Comment")
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end
  end
end
