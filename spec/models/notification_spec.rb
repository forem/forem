require "rails_helper"
require "sidekiq/testing"

RSpec.describe Notification, type: :model do
  let_it_be_readonly(:user)            { create(:user) }
  let_it_be_readonly(:user2)           { create(:user) }
  let_it_be_readonly(:user3)           { create(:user) }
  let_it_be_readonly(:organization)    { create(:organization) }
  let_it_be_changeable(:article) do
    create(:article, :with_notification_subscription, user: user, page_views_count: 4000, positive_reactions_count: 70)
  end
  let_it_be_readonly(:user_follows_user2) { user.follow(user2) }
  let_it_be_changeable(:comment) { create(:comment, user: user2, commentable: article) }
  let_it_be_readonly(:badge_achievement) { create(:badge_achievement) }

  it do
    scopes = %i[organization_id notifiable_id notifiable_type action]
    # rubocop:disable RSpec/NamedSubject
    expect(subject).to validate_uniqueness_of(:user_id).scoped_to(scopes)
    # rubocop:enable RSpec/NamedSubject
  end

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
      notification = create(
        :notification, user: user, notifiable: article, action: "Reaction", json_data: { "user_id" => 1 }
      )
      duplicate_notification = build(
        :notification, user: user, notifiable: article, action: "Reaction", json_data: { "user_id" => 2 }
      )
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
    end
  end

  context "when callbacks are triggered after create" do
    it "sets the notified_at column" do
      notification = create(:notification, notifiable: article, user: user2)
      expect(notification.notified_at).to be_present
    end
  end

  describe "#send_new_follower_notification" do
    context "when trying to a send notification after following a tag" do
      it "does not enqueue a notification job" do
        sidekiq_assert_no_enqueued_jobs(only: Notifications::NewFollowerWorker) do
          tag_follow = user.follow(create(:tag))
          described_class.send_new_follower_notification(tag_follow)
        end
      end
    end

    context "when trying to send a notification after following a user" do
      it "creates a notification belonging to the person being followed" do
        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_new_follower_notification(user_follows_user2)
          end
        end.to change(user2.notifications, :count).by(1)
      end

      it "creates a notification from the follow instance" do
        sidekiq_perform_enqueued_jobs do
          described_class.send_new_follower_notification(user_follows_user2)
        end

        notification = user2.notifications.last
        notifiable_data = { notifiable_id: notification.notifiable_id, notifiable_type: notification.notifiable_type }
        follow_data = { notifiable_id: user_follows_user2.id, notifiable_type: user_follows_user2.class.name }
        expect(notifiable_data).to eq(follow_data)
      end
    end

    context "when a user follows an organization" do
      let_it_be_readonly(:user_follows_organization) { user.follow(organization) }

      it "creates a notification belonging to the organization" do
        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_new_follower_notification(user_follows_organization)
          end
        end.to change(organization.notifications, :count).by(1)
      end

      it "does not create a notification belonging to a user" do
        sidekiq_perform_enqueued_jobs do
          described_class.send_new_follower_notification(user_follows_organization)
        end
        expect(organization.notifications.last&.user_id).to be(nil)
      end

      it "creates a notification from the follow instance" do
        sidekiq_perform_enqueued_jobs do
          described_class.send_new_follower_notification(user_follows_organization)
        end

        notification = organization.notifications.last
        notifiable_data = { notifiable_id: notification.notifiable_id, notifiable_type: notification.notifiable_type }
        follow_data = {
          notifiable_id: user_follows_organization.id,
          notifiable_type: user_follows_organization.class.name
        }
        expect(notifiable_data).to eq(follow_data)
      end
    end

    context "when a user unfollows another user" do
      it "destroys the follow notification" do
        # first we follow the user
        sidekiq_perform_enqueued_jobs do
          described_class.send_new_follower_notification(user_follows_user2)
        end

        # then we stop following them
        expect do
          sidekiq_perform_enqueued_jobs do
            user_stops_following_user2 = user.stop_following(user2)
            described_class.send_new_follower_notification(user_stops_following_user2)
          end
        end.to change(user2.notifications, :count).by(-1)
      end
    end
  end

  describe "#send_new_comment_notifications_without_delay" do
    let_it_be_changeable(:comment) { create(:comment, user: user2, commentable: article) }
    let_it_be_readonly(:child_comment) { create(:comment, user: user3, commentable: article, parent: comment) }

    context "when all commenters are subscribed" do
      it "sends a notification to the author of the article" do
        expect do
          described_class.send_new_comment_notifications_without_delay(comment)
        end.to change(user.notifications, :count).by(1)
      end

      it "does not send a notification to the author of the article if the commenter is the author" do
        comment = create(:comment, user: user, commentable: article)
        expect do
          described_class.send_new_comment_notifications_without_delay(comment)
        end.to change(user.notifications, :count).by(0)
      end

      it "does not send a notification to the author of the comment" do
        expect do
          described_class.send_new_comment_notifications_without_delay(comment)
        end.to change(user2.notifications, :count).by(0)
      end

      it "sends a notification to the author of the article about the child comment" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.to change(user.notifications, :count).by(1)
      end

      it "sends a notification to the organization" do
        create(:organization_membership, user: user, organization: organization)
        article.update(organization: organization)
        comment = create(:comment, user: user2, commentable: article)

        expect do
          described_class.send_new_comment_notifications_without_delay(comment)
        end.to change(organization.notifications, :count).by(1)
      end
    end

    context "when the author of the article is not subscribed" do
      before do
        article.update(receive_notifications: false)
        article.notification_subscriptions.delete_all
      end

      it "does not send a notification to the author of the article" do
        expect do
          described_class.send_new_comment_notifications_without_delay(comment)
        end.to change(user.notifications, :count).by(0)
      end

      it "doesn't send a notification to the author of the article about the child comment" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.to change(user.notifications, :count).by(0)
      end
    end

    context "when the author of a comment is not subscribed" do
      before do
        comment.update(receive_notifications: false)
      end

      it "does not send a notification to the author of the comment" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.to change(child_comment.user.notifications, :count).by(0)
      end

      it "sends a notification to the author of the article" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.to change(user.notifications, :count).by(1)
      end
    end
  end

  describe "#send_reaction_notification" do
    before do
      article.update(receive_notifications: true)
      comment.update(receive_notifications: true)
    end

    context "when reactable is receiving notifications" do
      it "sends a notification to the author of a comment" do
        reaction = create(:reaction, reactable: comment, user: user)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.to change(comment.user.notifications, :count).by(1)
      end

      it "sends a notification to the author of an article" do
        reaction = create(:reaction, reactable: article, user: user2)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.to change(article.user.notifications, :count).by(1)
      end

      it "does not send a notification to the author of an article if the reaction owner is deleted" do
        user4 = create(:user)
        reaction = create(:reaction, reactable: article, user: user4)
        user4.delete

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.not_to change(article.user.notifications, :count)
      end
    end

    context "when a reaction is destroyed" do
      let(:comment) { create(:comment, user: user2, commentable: article) }
      let!(:notification) { create(:notification, user: user, notifiable: comment, action: "Reaction") }
      let(:sibling_reaction) { create(:reaction, reactable: comment, user: user3) }

      it "destroys the notification if it exists" do
        reaction = create(:reaction, reactable: comment, user: user)
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        expect(described_class.exists?(id: notification.id)).to be(false)
      end

      it "keeps the notification if siblings exist" do
        reaction = create(:reaction, reactable: comment, user: user)
        sibling_reaction # to create it
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        notification.reload
        expect(notification).to be_persisted
      end

      it "doesn't keep data of the destroyed reaction in the notification" do
        reaction = create(:reaction, reactable: comment, user: user)
        sibling_reaction # to create it
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        notification.reload
        expect(notification.json_data["reaction"]["aggregated_siblings"].map { |s| s["user"]["id"] }).to eq([user3.id])
        # not the user of the destroyed reaction!
        expect(notification.json_data["user"]["id"]).to eq(user3.id)
      end

      it "creates and destroys the notification properly" do
        reaction = create(:reaction, user: user2, reactable: article, category: "like")

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.to change(user.notifications, :count).by(1)

        reaction.destroy!

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.to change(user.notifications, :count).by(-1)
      end
    end

    context "when reactable is not receiving notifications" do
      it "does not send a notification to the author of a comment" do
        comment = create(:comment, user: user2, commentable: article)
        comment.update(receive_notifications: false)
        reaction = create(:reaction, reactable: comment, user: user)

        expect do
          described_class.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        end.to change(user.notifications, :count).by(0)
      end

      it "does not send a notification to the author of an article" do
        article.update(receive_notifications: false)
        reaction = create(:reaction, reactable: article, user: user2)

        expect do
          described_class.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        end.to change(user.notifications, :count).by(0)
      end
    end

    context "when the reactable is an organization's article" do
      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        article.update(organization: organization)
      end

      it "creates a notification with the organization's ID" do
        reaction = create(:reaction, reactable: article, user: user2)
        expect do
          described_class.send_reaction_notification_without_delay(reaction, reaction.reactable.organization)
        end.to change(organization.notifications, :count).by(1)
      end
    end

    context "when dealing with positive and negative reactions" do
      it "creates a notification for a positive reaction" do
        reaction = create(:reaction, reactable: article, user: user2, category: "like")

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.to change(article.notifications, :count).by(1)
      end

      it "does not create a notification for a negative reaction" do
        user2.add_role(:trusted)
        reaction = create(:reaction, reactable: article, user: user2, category: "vomit")

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.to change(article.notifications, :count).by(0)
      end
    end
  end

  describe "#send_to_followers" do
    context "when the notifiable is an article from a user" do
      it "sends a notification to the author's followers" do
        user2.follow(user)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_followers(article, "Published")
          end
        end.to change(user2.notifications, :count).by(1)
      end
    end

    context "when the notifiable is an article from an organization" do
      let_it_be_readonly(:org_article) { create(:article, organization: organization, user: user) }

      it "sends a notification to author's followers" do
        user2.follow(user)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_followers(org_article, "Published")
          end
        end.to change(user2.notifications, :count).by(1)
      end

      it "sends a notification to the organization's followers" do
        user3.follow(organization)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_followers(org_article, "Published")
          end
        end.to change(user3.notifications, :count).by(1)
      end
    end
  end

  describe "#update_notifications" do
    context "when there are article notifications to update" do
      before do
        user2.follow(user)
        sidekiq_perform_enqueued_jobs { described_class.send_to_followers(article, "Published") }
      end

      it "updates the notification with the new article title" do
        new_title = "hehehe hohoho!"
        article.update_attribute(:title, new_title)
        described_class.update_notifications(article, "Published")

        sidekiq_perform_enqueued_jobs

        expected_notification_article_title = user2.notifications.last.json_data["article"]["title"]
        expect(expected_notification_article_title).to eq(new_title)
      end

      it "adds organization data when the article now belongs to an org" do
        article.update(organization_id: organization.id)
        described_class.update_notifications(article, "Published")

        sidekiq_perform_enqueued_jobs

        expected_notification_organization_id = described_class.last.json_data["organization"]["id"]
        expect(expected_notification_organization_id).to eq(organization.id)
      end
    end
  end

  describe "#aggregated?" do
    let_it_be_readonly(:notification) { build(:notification) }
    it "returns true if a notification's action is 'Reaction'" do
      notification.action = "Reaction"
      expect(notification.aggregated?).to be(true)
    end

    it "returns true if a notification's action is 'Follow'" do
      notification.action = "Follow"
      expect(notification.aggregated?).to be(true)
    end

    it "returns false if a notification's action is not 'Reaction' or 'Follow'" do
      notification.action = "Published"
      expect(notification.aggregated?).to be(false)
    end
  end

  describe "#send_new_badge_achievement_notification" do
    it "enqueues a new badge achievement job" do
      sidekiq_assert_enqueued_with(job: Notifications::NewBadgeAchievementWorker, args: [badge_achievement.id]) do
        described_class.send_new_badge_achievement_notification(badge_achievement)
      end
    end
  end

  describe "#remove_all" do
    it "removes all mention related notifications" do
      mention = create(:mention, user: user, mentionable: comment)
      create(:notification, user: mention.user, notifiable: mention)

      expect do
        sidekiq_perform_enqueued_jobs do
          described_class.remove_all(notifiable_ids: mention.id, notifiable_type: "Mention")
        end
      end.to change(user.notifications, :count).by(-1)
    end
  end

  describe "#fast_destroy_old_notifications" do
    it "bulk deletes notifications older than given timestamp" do
      allow(BulkSqlDelete).to receive(:delete_in_batches)
      described_class.fast_destroy_old_notifications("a_time")
      expect(BulkSqlDelete).to have_received(:delete_in_batches).with(a_string_including("< 'a_time'"))
    end
  end
end
