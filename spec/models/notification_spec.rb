require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:organization)    { create(:organization) }
  let(:article)         { create(:article, :with_notification_subscription, user_id: user.id, page_views_count: 4000, positive_reactions_count: 70) }
  let(:follow_instance) { user.follow(user2) }
  let(:badge_achievement) { create(:badge_achievement) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[organization_id notifiable_id notifiable_type action]) }

  describe "when trying to create duplicate notifications" do
    # Duplicate notifications are not allowed even when validations are skipped
    it "doesn't allow to create a duplicate notification via import" do
      create(:notification, user: user, notifiable: article, action: "Reaction")
      duplicate_notification = build(:notification, user: user, notifiable: article, action: "Reaction")
      expect do
        described_class.import([duplicate_notification],
                               on_duplicate_key_update: {
                                 conflict_target: %i[notifiable_id notifiable_type user_id action],
                                 index_predicate: "action IS NOT NULL",
                                 columns: %i[json_data notified_at read]
                               })
      end.not_to change(described_class, :count)
    end

    it "updates when trying to create a duplicate notification via import" do
      notification = create(:notification, user: user, notifiable: article, action: "Reaction", json_data: { "user_id" => 1 })
      duplicate_notification = build(:notification, user: user, notifiable: article, action: "Reaction", json_data: { "user_id" => 2 })
      described_class.import([duplicate_notification],
                             on_duplicate_key_update: {
                               conflict_target: %i[notifiable_id notifiable_type user_id action],
                               index_predicate: "action IS NOT NULL",
                               columns: %i[json_data notified_at read]
                             })
      notification.reload
      expect(notification.json_data["user_id"]).to eq(2)
    end

    it "doesn't allow to create a duplicate organization notification via import" do
      create(:notification, organization: organization, notifiable: article, action: "Reaction")
      duplicate_notification = build(:notification, organization: organization, notifiable: article, action: "Reaction")
      expect do
        described_class.import([duplicate_notification],
                               on_duplicate_key_update: {
                                 conflict_target: %i[notifiable_id notifiable_type organization_id action],
                                 index_predicate: "action IS NOT NULL",
                                 columns: %i[json_data notified_at read]
                               })
      end.not_to change(described_class, :count)
    end

    describe "when notifiable is a Comment" do
      let!(:comment) { create(:comment, commentable: article) }

      # rubocop:disable RSpec/ExampleLength
      it "doesn't allow to create a duplicate user notification via import when action is nil" do
        notification_attributes = { user: user, notifiable: comment, action: nil }
        create(:notification, notification_attributes)
        duplicate_notification = build(:notification, notification_attributes)
        expect do
          described_class.import([duplicate_notification],
                                 on_duplicate_key_update: {
                                   conflict_target: %i[notifiable_id notifiable_type user_id],
                                   index_predicate: "action IS NULL",
                                   columns: %i[json_data notified_at read]
                                 })
        end.not_to change(described_class, :count)
      end

      it "doesn't allow to create a duplicate org notification via import when action is nil" do
        notification_attributes = { organization: organization, notifiable: comment, action: nil }
        create(:notification, notification_attributes)
        duplicate_notification = build(:notification, notification_attributes)
        expect do
          described_class.import([duplicate_notification],
                                 on_duplicate_key_update: {
                                   conflict_target: %i[notifiable_id notifiable_type organization_id],
                                   index_predicate: "action IS NULL",
                                   columns: %i[json_data notified_at read]
                                 })
        end.not_to change(described_class, :count)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  describe "when trying to #send_new_follower_notification after following a tag" do
    let(:tag) { create(:tag) }
    let(:tag_follow) { user.follow(tag) }

    it "runs fine" do
      run_background_jobs_immediately do
        described_class.send_new_follower_notification(tag_follow)
      end
    end

    it "doesn't create a notification" do
      run_background_jobs_immediately do
        expect do
          described_class.send_new_follower_notification(tag_follow)
        end.not_to change(described_class, :count)
      end
    end
  end

  describe "#send_new_follower_notification" do
    before do
      perform_enqueued_jobs do
        described_class.send_new_follower_notification(follow_instance)
      end
    end

    it "sets the notifiable_at column upon creation" do
      expect(described_class.last.notified_at).not_to eq nil
    end

    context "when a user follows another user" do
      it "creates a notification belonging to the person being followed" do
        expect(described_class.first.user_id).to eq user2.id
      end

      it "creates a notification from the follow instance" do
        notifiable_data = { notifiable_id: described_class.first.notifiable_id, notifiable_type: described_class.first.notifiable_type }
        follow_data = { notifiable_id: follow_instance.id, notifiable_type: follow_instance.class.name }
        expect(notifiable_data).to eq follow_data
      end
    end

    context "when a user follows an organization" do
      let(:follow_instance) { user.follow(organization) }

      it "creates a notification belonging to the organization" do
        expect(described_class.first.organization_id).to eq organization.id
      end

      it "does not create a notification belonging to a user" do
        expect(described_class.first.user_id).to eq nil
      end

      it "creates a notification from the follow instance" do
        notifiable_data = { notifiable_id: described_class.first.notifiable_id, notifiable_type: described_class.first.notifiable_type }
        follow_data = { notifiable_id: follow_instance.id, notifiable_type: follow_instance.class.name }
        expect(notifiable_data).to eq follow_data
      end
    end

    context "when a user unfollows another user" do
      it "destroys the follow notification" do
        follow_instance = user.stop_following(user2)
        perform_enqueued_jobs do
          described_class.send_new_follower_notification(follow_instance)
        end
        expect(described_class.count).to eq 0
      end
    end
  end

  describe "#send_new_comment_notifications" do
    context "when all commenters are subscribed" do
      it "sends a notification to the author of the article" do
        comment = create(:comment, user: user2, commentable: article)
        described_class.send_new_comment_notifications_without_delay(comment)
        expect(user.notifications.count).to eq 1
      end

      it "does not send a notification to the author of the article if the commenter is the author" do
        comment = create(:comment, user: user, commentable: article)
        described_class.send_new_comment_notifications_without_delay(comment)
        expect(user.notifications.count).to eq 0
      end

      it "does not send a notification to the author of the comment" do
        comment = create(:comment, user: user2, commentable: article)
        described_class.send_new_comment_notifications_without_delay(comment)
        expect(user2.notifications.count).to eq 0
      end

      it "sends a notification to the author of the article about the child comment" do
        parent_comment = create(:comment, user: user2, commentable: article)
        child_comment = create(:comment, user: user3, commentable: article, ancestry: parent_comment.id.to_s)
        described_class.send_new_comment_notifications_without_delay(child_comment)
        expect(user.notifications.count).to eq(1)
      end

      it "sends a notification to the organization" do
        org = create(:organization)
        create(:organization_membership, user: user, organization: org)
        article.update(organization: org)
        comment = create(:comment, user: user2, commentable: article)
        described_class.send_new_comment_notifications_without_delay(comment)
        expect(org.notifications.count).to eq 1
      end
    end

    context "when the author of the article is not subscribed" do
      let!(:comment) { create(:comment, user: user2, commentable: article) }

      before do
        article.update(receive_notifications: false)
        article.notification_subscriptions.delete_all
      end

      it "does not send a notification to the author of the article" do
        described_class.send_new_comment_notifications_without_delay(comment)
        expect(user.notifications.count).to eq 0
      end

      it "doesn't send a notification to the author of the article about the child comment" do
        child_comment = create(:comment, user: user3, commentable: article, ancestry: comment.id.to_s)
        described_class.send_new_comment_notifications_without_delay(child_comment)
        expect(user.notifications.count).to eq 0
      end
    end

    context "when the author of a comment is not subscribed" do
      let(:parent_comment) { create(:comment, user: user2, commentable: article) }
      let!(:child_comment) { create(:comment, user: user3, commentable: article, ancestry: parent_comment.id.to_s) }

      before do
        parent_comment.update(receive_notifications: false)
      end

      it "does not send a notification to the author of the comment" do
        described_class.send_new_comment_notifications_without_delay(child_comment)
        expect(user2.notifications.count).to eq 0
      end

      it "sends a notification to the author of the article" do
        described_class.send_new_comment_notifications_without_delay(child_comment)
        expect(user.notifications.count).to eq(1)
      end
    end
  end

  describe "#send_reaction_notification" do
    context "when reactable is receiving notifications" do
      it "sends a notification to the author of a comment" do
        comment = create(:comment, user: user2, commentable: article)
        reaction = create(:reaction, reactable: comment, user: user)
        perform_enqueued_jobs do
          described_class.send_reaction_notification(reaction, reaction.reactable.user)
          expect(user2.notifications.count).to eq 1
        end
      end

      it "sends a notification to the author of an article" do
        reaction = create(:reaction, reactable: article, user: user2)
        perform_enqueued_jobs do
          described_class.send_reaction_notification(reaction, reaction.reactable.user)
          expect(user.notifications.count).to eq 1
        end
      end
    end

    context "when a reaction is destroyed" do
      let(:comment) { create(:comment, user: user2, commentable: article) }
      let!(:notification) { create(:notification, user: user, notifiable: comment, action: "Reaction") }

      it "destroys the notification if it exists" do
        reaction = create(:reaction, reactable: comment, user: user)
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        expect(described_class.where(id: notification.id)).not_to be_any
      end

      it "keeps the notification if siblings exist" do
        reaction = create(:reaction, reactable: comment, user: user)
        create(:reaction, reactable: comment, user: user3)
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        notification.reload
        expect(notification).to be_persisted
      end

      it "doesn't keep data of the destroyed reaction in the notification" do
        reaction = create(:reaction, reactable: comment, user: user)
        create(:reaction, reactable: comment, user: user3)
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        notification.reload
        expect(notification.json_data["reaction"]["aggregated_siblings"].map { |s| s["user"]["id"] }).to eq([user3.id])
        # not the user of the destroyed reaction!
        expect(notification.json_data["user"]["id"]).to eq(user3.id)
      end
    end

    context "when reactable is not receiving notifications" do
      it "does not send a notification to the author of a comment" do
        comment = create(:comment, user: user2, commentable: article)
        comment.update(receive_notifications: false)
        reaction = create(:reaction, reactable: comment, user: user)
        described_class.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        expect(user2.notifications.count).to eq 0
      end

      it "does not send a notification to the author of an article" do
        article.update(receive_notifications: false)
        reaction = create(:reaction, reactable: article, user: user2)
        described_class.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        expect(user.notifications.count).to eq 0
      end
    end

    context "when the reactable is an organization's article" do
      let(:org) { create(:organization) }

      before do
        create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        article.update(organization: org)
      end

      it "creates a notification with the organization's ID" do
        reaction = create(:reaction, reactable: article, user: user2)
        described_class.send_reaction_notification_without_delay(reaction, reaction.reactable.organization)
        expect(org.notifications.count).to eq 1
      end
    end

    it "creates positive reaction notification" do
      reaction = article.reactions.create!(
        user_id: user2.id,
        category: "like",
      )
      perform_enqueued_jobs do
        expect do
          described_class.send_reaction_notification(reaction, reaction.reactable.user)
        end.to change(described_class, :count).by(1)
      end
    end

    it "does not create negative notification" do
      user2.add_role(:trusted)
      reaction = article.reactions.create!(
        user_id: user2.id,
        category: "vomit",
      )
      perform_enqueued_jobs do
        expect do
          described_class.send_reaction_notification(reaction, reaction.reactable.user)
        end.not_to change(described_class, :count)
      end
    end

    it "destroys the notification properly" do
      reaction = create(:reaction, user: user2, reactable: article, category: "like")
      perform_enqueued_jobs do
        described_class.send_reaction_notification(reaction, reaction.reactable.user)
        reaction.destroy!
        described_class.send_reaction_notification(reaction, reaction.reactable.user)
        expect(described_class.count).to eq 0
      end
    end
  end

  describe "#send_to_followers" do
    context "when the notifiable is an article from a user" do
      before do
        user2.follow(user)
        perform_enqueued_jobs { described_class.send_to_followers(article, "Published") }
      end

      it "sends a notification to the author's followers" do
        expect(described_class.first.user_id).to eq user2.id
      end
    end

    context "when the notifiable is an article from an organization" do
      let(:article) { create(:article, organization_id: organization.id, user_id: user.id) }

      before do
        user2.follow(user)
        user3.follow(organization)
        perform_enqueued_jobs { described_class.send_to_followers(article, "Published") }
      end

      it "sends a notification to author's followers" do
        expect(user2.notifications.count).to eq 1
      end

      it "sends a notification to the organization's followers" do
        expect(user3.notifications.count).to eq 1
      end
    end
  end

  describe "#update_notifications" do
    context "when there are article notifications to update" do
      before do
        user2.follow(user)
        described_class.send_to_followers_without_delay(article, "Published")
      end

      it "updates the notification with the new article title" do
        new_title = "hehehe hohoho!"
        article.update_column(:title, new_title)
        article.reload
        perform_enqueued_jobs do
          described_class.update_notifications(article, "Published")
          first_notification_article_title = described_class.first.json_data["article"]["title"]
          expect(first_notification_article_title).to eq new_title
        end
      end

      it "adds organization data when the article now belongs to an org" do
        article.update_column(:organization_id, organization.id)
        article.reload
        perform_enqueued_jobs do
          described_class.update_notifications(article.reload, "Published")
          first_notification_organization_id = described_class.first.json_data["organization"]["id"]
          expect(first_notification_organization_id).to eq organization.id
        end
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

  describe "#send_new_badge_achievement_notification" do
    it "enqueues a new badge achievement job" do
      assert_enqueued_with(job: Notifications::NewBadgeAchievementJob, args: [badge_achievement.id]) do
        described_class.send_new_badge_achievement_notification(badge_achievement)
      end
    end
  end

  describe "#send_new_badge_notification (deprecated)" do
    it "enqueues a new badge achievement job" do
      assert_enqueued_with(job: Notifications::NewBadgeAchievementJob, args: [badge_achievement.id]) do
        described_class.send_new_badge_notification(badge_achievement)
      end
    end
  end

  describe "#send_new_badge_notification_without_delay (deprecated)" do
    it "creates a notification" do
      expect do
        described_class.send_new_badge_notification_without_delay(badge_achievement)
      end.to change(described_class, :count).by(1)
    end
  end

  describe "#remove_each" do
    let(:mention) { create(:mention, user_id: user.id, mentionable_id: comment.id, mentionable_type: "Comment") }
    let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }
    let(:notifiable_collection) { [mention] }

    before do
      create(:notification, user_id: mention.user_id, notifiable_id: mention.id, notifiable_type: "Mention")
    end

    it "removes each mention related notifiable" do
      perform_enqueued_jobs do
        expect do
          described_class.remove_each(notifiable_collection)
        end.to change(described_class, :count).by(-1)
      end
    end
  end
end
