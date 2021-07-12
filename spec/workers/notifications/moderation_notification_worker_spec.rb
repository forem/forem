require "rails_helper"

RSpec.describe Notifications::ModerationNotificationWorker do
  let(:id) { rand(1000) }
  let(:comment) do
    comment = double
    allow(Comment).to receive(:find_by).and_return(comment)
    allow(comment).to receive(:user)
    allow(comment).to receive(:commentable).and_return(true)
    comment
  end
  let(:mod) do
    last_moderation_time = Time.current - Notifications::Moderation::MODERATORS_AVAILABILITY_DELAY - 1.week
    u = create(:user, :trusted, last_moderation_notification: last_moderation_time)
    u.notification_setting.update(mod_roundrobin_notifications: true)
    u
  end
  let(:worker) { subject }

  def check_received_call
    worker.perform(id)
    expect(Notifications::Moderation::Send).to have_received(:call)
  end

  def check_non_received_call
    worker.perform(id)
    expect(Notifications::Moderation::Send).not_to have_received(:call)
  end

  describe "#perform" do
    before do
      allow(Notifications::Moderation::Send).to receive(:call)
    end

    describe "When available moderator(s) + comment" do
      it "calls the service" do
        mod
        comment
        check_received_call
      end
    end

    describe "When no available moderator" do
      it "does not call the service" do
        comment
        check_non_received_call
      end
    end

    describe "When no valid comment" do
      it "does not call the service" do
        mod
        check_non_received_call
      end
    end

    describe "When no valid comment + no moderator" do
      it "does not call the service" do
        check_non_received_call
      end
    end

    describe "when moderator is the comment author" do
      it "does not call the service" do
        comment = create(:comment, user: mod, commentable: create(:article))
        worker.perform(comment.id)
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end

    describe "when the commentable does not exist" do
      it "does not call the service" do
        mod # prepare a moderator

        article = create(:article)
        comment = create(:comment, commentable: article)

        article.destroy!

        worker.perform(comment.id)
        expect(Notifications::Moderation::Send).not_to have_received(:call)
      end
    end
  end
end
