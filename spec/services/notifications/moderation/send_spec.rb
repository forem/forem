require "rails_helper"

RSpec.describe Notifications::Moderation::Send, type: :service do
  let(:last_moderation_time) { Time.zone.now - Notifications::Moderation::MODERATORS_AVAILABILITY_DELAY - 1.week }
  let(:staff_account) { create(:user) }
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user: user, commentable: article) }
  let(:selected_moderators) { Users::SelectModeratorsQuery.call }
  let(:moderator) { selected_moderators.first }

  context "when notifying on comments" do
    before do
      u = create(:user, :trusted, last_reacted_at: 2.days.ago, last_moderation_notification: last_moderation_time)
      u.notification_setting.update(mod_roundrobin_notifications: true)
      allow(User).to receive(:staff_account).and_return(staff_account)
      # Creating a comment calls moderation job which itself call moderation service
      Comment.skip_callback(:commit, :after, :send_to_moderator)
    end

    after do
      Comment.set_callback(:commit, :after, :send_to_moderator)
    end

    it "calls comment_data since parameter is a comment" do
      allow(Notifications).to receive(:comment_data)
      described_class.call(moderator, comment)
      expect(Notifications).to have_received(:comment_data)
    end

    it "checks whether Notification is inserted on DB" do
      expect do
        described_class.call(moderator, comment)
      end.to change(Notification, :count).by(1)
    end

    it "checks whether created Notification is valid", :aggregate_failures do
      notification = described_class.call(moderator, comment)
      expect(notification).to be_a Notification
      expect(notification.action).to eq "Moderation"
      expect(notification.notifiable_type).to eq "Comment"
      expect(notification.user_id).to eq moderator.id
      expect(notification.notifiable_id).to eq comment.id
    end

    it "checks that moderator last notification time updates" do
      expect do
        described_class.call(moderator, comment)
      end.to change(moderator, :last_moderation_notification)
    end

    it "does not create a notification if the moderator is the comment's author" do
      comment = create(:comment, user: moderator, commentable: article)

      expect do
        described_class.call(moderator, comment)
      end.not_to change(Notification, :count)
    end

    it "includes all needed user data in the notification" do
      notification = described_class.call(moderator, comment)

      expect(notification.json_data["user"]["id"]).to eq(staff_account.id)
      expect(notification.json_data["comment_user"]["id"]).to eq(comment.user.id)
    end
  end

  context "when notifying on articles" do
    before do
      u = create(:user, :trusted, last_reacted_at: 2.days.ago, last_moderation_notification: last_moderation_time)
      u.notification_setting.update(mod_roundrobin_notifications: true)
      allow(User).to receive(:staff_account).and_return(staff_account)
      # Creating an article calls moderation job which itself calls moderation service
      Article.skip_callback(:commit, :after, :send_to_moderator)
    end

    after do
      Article.set_callback(:commit, :after, :send_to_moderator)
    end

    it "calls article_data since parameter is an article" do
      allow(Notifications).to receive(:article_data)
      described_class.call(moderator, article)
      expect(Notifications).to have_received(:article_data)
    end

    it "checks whether Notification is inserted on DB" do
      expect do
        described_class.call(moderator, article)
      end.to change(Notification, :count).by(1)
    end

    it "checks whether created Notification is valid", :aggregate_failures do
      notification = described_class.call(moderator, article)
      expect(notification).to be_a Notification
      expect(notification.action).to eq "Moderation"
      expect(notification.notifiable_type).to eq "Article"
      expect(notification.user_id).to eq moderator.id
      expect(notification.notifiable_id).to eq article.id
    end

    it "checks that moderator last notification time updates" do
      expect do
        described_class.call(moderator, article)
      end.to change(moderator, :last_moderation_notification)
    end

    it "does not create a notification if the moderator is the article's author" do
      article = create(:article, user: moderator)

      expect do
        described_class.call(moderator, article)
      end.not_to change(Notification, :count)
    end

    it "includes all needed user data in the notification" do
      notification = described_class.call(moderator, article)

      expect(notification.json_data["user"]["id"]).to eq(staff_account.id)
      expect(notification.json_data["article_user"]["id"]).to eq(article.user.id)
    end
  end
end
