require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:article)         { create(:article, user_id: user.id) }
  let(:follow_instance) { user.follow(user2) }

  describe "#send_new_follower_notification" do
    before { Notification.send_new_follower_notification(follow_instance) }

    it "creates a notification belonging to the person being followed" do
      expect(Notification.first.user_id).to eq user2.id
    end

    it "creates a notification from the follow instance" do
      notifiable_data = { notifiable_id: Notification.first.notifiable_id, notifiable_type: Notification.first.notifiable_type }
      follow_data = { notifiable_id: follow_instance.id, notifiable_type: follow_instance.class.name }
      expect(notifiable_data).to eq follow_data
    end

    it "is given notifiable_at upon creation" do
      expect(Notification.last.notified_at).not_to eq nil
    end

    it "creates positive reaction notification" do
      reaction = Reaction.create!(
        user_id: user2.id,
        reactable_id: article.id,
        reactable_type: "Article",
        category: "like",
      )
      notification = Notification.send_reaction_notification_without_delay(reaction)
      expect(notification).to be_valid
    end

    it "does not create negative notification" do
      user2.add_role(:trusted)
      reaction = Reaction.create!(
        user_id: user2.id,
        reactable_id: article.id,
        reactable_type: "Article",
        category: "vomit",
      )
      notification = Notification.send_reaction_notification_without_delay(reaction)
      expect(notification).to eq nil
    end
  end

  describe "#send_new_comment_notifications" do
    context "when all commenters are subscribed" do
      it "sends a notification to the author of the article" do
        comment = create(:comment, user: user2, commentable: article)
        Notification.send_new_comment_notifications_without_delay(comment)
        expect(user.notifications.count).to eq 1
      end

      it "does not send a notification to the author of the article if the commenter is the author" do
        comment = create(:comment, user: user, commentable: article)
        Notification.send_new_comment_notifications_without_delay(comment)
        expect(user.notifications.count).to eq 0
      end

      it "does not send a notification to the author of the comment" do
        comment = create(:comment, user: user2, commentable: article)
        Notification.send_new_comment_notifications_without_delay(comment)
        expect(user2.notifications.count).to eq 0
      end
    end

    context "when the author of the article is not subscribed" do
      it "does not send a notification to the author of the article" do
        article.update(receive_notifications: false)
        comment = create(:comment, user: user2, commentable: article)
        Notification.send_new_comment_notifications_without_delay(comment)
        expect(user.notifications.count).to eq 0
      end
    end

    context "when the author of a comment is not subscribed" do
      it "does not send a notification to the author of the comment" do
        original_comment = create(:comment, user: user2, commentable: article)
        original_comment.update(receive_notifications: false)
        comment_on_comment = create(:comment, user: user, commentable: article)
        Notification.send_new_comment_notifications_without_delay(comment_on_comment)
        expect(user2.notifications.count).to eq 0
      end
    end
  end

  describe "#send_reaction_notification" do
    context "when reactable is receiving notifications" do
      it "sends a notification to the author of a comment" do
        comment = create(:comment, user: user2, commentable: article)
        reaction = create(:reaction, reactable: comment, user: user)
        Notification.send_reaction_notification_without_delay(reaction)
        expect(user2.notifications.count).to eq 1
      end

      it "sends a notification to the author of an article" do
        reaction = create(:reaction, reactable: article, user: user2)
        Notification.send_reaction_notification_without_delay(reaction)
        expect(user.notifications.count).to eq 1
      end
    end

    context "when reactable is not receiving notifications" do
      it "does not send a notification to the author of a comment" do
        comment = create(:comment, user: user2, commentable: article)
        comment.update(receive_notifications: false)
        reaction = create(:reaction, reactable: comment, user: user)
        Notification.send_reaction_notification_without_delay(reaction)
        expect(user2.notifications.count).to eq 0
      end

      it "does not send a notification to the author of an article" do
        article.update(receive_notifications: false)
        reaction = create(:reaction, reactable: article, user: user2)
        Notification.send_reaction_notification_without_delay(reaction)
        expect(user.notifications.count).to eq 0
      end
    end
  end
end
