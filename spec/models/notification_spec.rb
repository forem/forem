require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:organization)    { create(:organization) }
  let(:article)         { create(:article, user_id: user.id, page_views_count: 4000, positive_reactions_count: 70) }
  let(:follow_instance) { user.follow(user2) }

  describe "when trying to #send_new_follower_notification after following a tag" do
    let(:tag) { create(:tag) }
    let(:tag_follow) { user.follow(tag) }

    it "runs fine" do
      run_background_jobs_immediately do
        Notification.send_new_follower_notification(tag_follow)
      end
    end

    it "doesn't create a notification" do
      run_background_jobs_immediately do
        expect do
          Notification.send_new_follower_notification(tag_follow)
        end.not_to change(Notification, :count)
      end
    end
  end

  describe "#send_new_follower_notification" do
    before do
      run_background_jobs_immediately do
        Notification.send_new_follower_notification(follow_instance)
      end
    end

    it "sets the notifiable_at column upon creation" do
      expect(Notification.last.notified_at).not_to eq nil
    end

    context "when a user follows another user" do
      it "creates a notification belonging to the person being followed" do
        expect(Notification.first.user_id).to eq user2.id
      end

      it "creates a notification from the follow instance" do
        notifiable_data = { notifiable_id: Notification.first.notifiable_id, notifiable_type: Notification.first.notifiable_type }
        follow_data = { notifiable_id: follow_instance.id, notifiable_type: follow_instance.class.name }
        expect(notifiable_data).to eq follow_data
      end
    end

    context "when a user follows an organization" do
      let(:follow_instance) { user.follow(organization) }

      it "creates a notification belonging to the organization" do
        expect(Notification.first.organization_id).to eq organization.id
      end

      it "does not create a notification belonging to a user" do
        expect(Notification.first.user_id).to eq nil
      end

      it "creates a notification from the follow instance" do
        notifiable_data = { notifiable_id: Notification.first.notifiable_id, notifiable_type: Notification.first.notifiable_type }
        follow_data = { notifiable_id: follow_instance.id, notifiable_type: follow_instance.class.name }
        expect(notifiable_data).to eq follow_data
      end
    end

    context "when a user unfollows another user" do
      it "destroys the follow notification" do
        follow_instance = user.stop_following(user2)
        run_background_jobs_immediately { Notification.send_new_follower_notification(follow_instance) }
        expect(Notification.count).to eq 0
      end
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

      it "sends a notification to the organization" do
        org = create(:organization)
        user.update(organization: org)
        article.update(organization: org)
        comment = create(:comment, user: user2, commentable: article)
        Notification.send_new_comment_notifications_without_delay(comment)
        expect(org.notifications.count).to eq 1
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
        parent_comment = create(:comment, user: user2, commentable: article)
        parent_comment.update(receive_notifications: false)
        child_comment = create(:comment, user: user, commentable: article, ancestry: parent_comment.id.to_s)
        Notification.send_new_comment_notifications_without_delay(child_comment)
        expect(user2.notifications.count).to eq 0
      end
    end
  end

  describe "#send_reaction_notification" do
    context "when reactable is receiving notifications" do
      it "sends a notification to the author of a comment" do
        comment = create(:comment, user: user2, commentable: article)
        reaction = create(:reaction, reactable: comment, user: user)
        Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        expect(user2.notifications.count).to eq 1
      end

      it "sends a notification to the author of an article" do
        reaction = create(:reaction, reactable: article, user: user2)
        Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        expect(user.notifications.count).to eq 1
      end
    end

    context "when reactable is not receiving notifications" do
      it "does not send a notification to the author of a comment" do
        comment = create(:comment, user: user2, commentable: article)
        comment.update(receive_notifications: false)
        reaction = create(:reaction, reactable: comment, user: user)
        Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        expect(user2.notifications.count).to eq 0
      end

      it "does not send a notification to the author of an article" do
        article.update(receive_notifications: false)
        reaction = create(:reaction, reactable: article, user: user2)
        Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        expect(user.notifications.count).to eq 0
      end
    end

    context "when the reactable is an organization's article" do
      let(:org) { create(:organization) }

      before do
        user.update(organization: org, org_admin: true)
        article.update(organization: org)
      end

      it "creates a notification with the organization's ID" do
        reaction = create(:reaction, reactable: article, user: user2)
        Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.organization)
        expect(org.notifications.count).to eq 1
      end
    end

    it "creates positive reaction notification" do
      reaction = Reaction.create!(
        user_id: user2.id,
        reactable_id: article.id,
        reactable_type: "Article",
        category: "like",
      )
      notification = Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
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
      notification = Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
      expect(notification).to eq nil
    end

    it "destroys the notification properly" do
      reaction = create(:reaction, user: user2, reactable: article, category: "like")
      Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
      reaction.destroy!
      Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
      expect(Notification.count).to eq 0
    end
  end

  describe "#send_to_followers" do
    context "when the notifiable is an article from a user" do
      before do
        user2.follow(user)
        run_background_jobs_immediately { Notification.send_to_followers(article, "Published") }
      end

      it "sends a notification to the author's followers" do
        expect(Notification.first.user_id).to eq user2.id
      end
    end

    context "when the notifiable is an article from an organization" do
      let(:article) { create(:article, organization_id: organization.id, user_id: user.id) }

      before do
        user2.follow(user)
        user3.follow(organization)
        run_background_jobs_immediately { Notification.send_to_followers(article, "Published") }
      end

      it "sends a notification to author's followers" do
        expect(user2.notifications.count).to eq 1
      end

      it "sends a notification to the organization's followers" do
        expect(user3.notifications.count).to eq 1
      end
    end
  end

  describe "#send_tag_adjustment_notification" do
    let(:tag)             { create(:tag) }
    let(:article)         { create(:article, user: user2, body_markdown: "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey,#{tag.name}\n---\n\nHello") }
    let(:tag_adjustment)  { create(:tag_adjustment, tag: tag, user: user, article: article) }

    before do
      user.add_role(:tag_moderator, tag)
    end

    it "notifies the author of the article" do
      Notification.send_tag_adjustment_notification_without_delay(tag_adjustment)
      expect(Notification.first.user_id).to eq user2.id
    end

    it "updates the author's last_moderation_notification" do
      original_last_moderation_notification_timestamp = user2.last_moderation_notification
      Notification.send_tag_adjustment_notification_without_delay(tag_adjustment)
      expect(user2.reload.last_moderation_notification).to be > original_last_moderation_notification_timestamp
    end
  end

  describe "#send_milestone_notification" do
    # milestones = [64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144]
    let(:view_milestone_hash) { { type: "View", article: article } }
    let(:reaction_milestone_hash) { { type: "Reaction", article: article } }

    context "when a user has never received a milestone notification" do
      it "sends the appropriate level view milestone notification" do
        Notification.send_milestone_notification_without_delay(view_milestone_hash)
        expect(user.notifications.first.action).to include "2048"
      end

      it "sends the appropriate level reaction milestone notification" do
        Notification.send_milestone_notification_without_delay(reaction_milestone_hash)
        expect(user.notifications.first.action).to include "64"
      end
    end

    context "when a user has received a milestone notification before" do
      def mock_previous_view_milestone_notification
        Notification.send_milestone_notification_without_delay(view_milestone_hash)
        article.update_column(:page_views_count, 9001)
        Notification.send_milestone_notification_without_delay(view_milestone_hash)
      end

      def mock_previous_reaction_milestone_notification
        Notification.send_milestone_notification_without_delay(reaction_milestone_hash)
        article.update_column(:positive_reactions_count, 150)
        Notification.send_milestone_notification_without_delay(reaction_milestone_hash)
      end

      it "sends the appropriate level view milestone notification" do
        mock_previous_view_milestone_notification
        expect(user.notifications.second.action).to include "8192"
      end

      it "sends the appropriate level reaction milestone notification" do
        mock_previous_reaction_milestone_notification
        expect(user.notifications.last.action).to include "128"
      end

      it "adds an additional view milestone notification" do
        mock_previous_view_milestone_notification
        expect(user.notifications.count).to eq 2
      end

      it "does not the same view milestone notification if called again" do
        mock_previous_view_milestone_notification
        Notification.send_milestone_notification_without_delay(view_milestone_hash)
        expect(user.notifications.count).to eq 2
      end

      it "does not send a view milestone notification again if the latest number of views is not past the next milestone" do
        mock_previous_view_milestone_notification
        article.update_column(:page_views_count, rand(9002..16_383))
        Notification.send_milestone_notification_without_delay(view_milestone_hash)
        expect(user.notifications.count).to eq 2
      end
    end
  end

  describe "#update_notifications" do
    context "when there are no notifications to begin with" do
      it "returns nil" do
        expect(Notification.update_notifications_without_delay(article, "Published")).to be nil
      end
    end

    context "when there are notifications to update" do
      before do
        user2.follow(user)
        Notification.send_to_followers_without_delay(article, "Published")
      end

      it "updates the notification with the new article title" do
        new_title = "hehehe hohoho!"
        article.update_column(:title, new_title)
        Notification.update_notifications_without_delay(article.reload, "Published")
        first_notification_article_title = Notification.first.json_data["article"]["title"]
        expect(first_notification_article_title).to eq new_title
      end

      it "adds organization data when the article now belongs to an org" do
        article.update_column(:organization_id, organization.id)
        Notification.update_notifications_without_delay(article.reload, "Published")
        first_notification_organization_id = Notification.first.json_data["organization"]["id"]
        expect(first_notification_organization_id).to eq organization.id
      end
    end
  end

  describe "#aggregated?" do
    it "returns true if a notification's action is 'Reaction'" do
      notification = build(:notification, action: "Reaction")
      expect(notification.aggregated?).to eq true
    end

    it "returns true if a notification's action is 'Follow'" do
      notification = build(:notification, action: "Follow")
      expect(notification.aggregated?).to eq true
    end

    it "returns false if a notification's action is not 'Reaction' or 'Follow'" do
      notification = build(:notification, action: "Published")
      expect(notification.aggregated?).to eq false
    end
  end
end
