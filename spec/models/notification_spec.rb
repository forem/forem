require "rails_helper"
require "sidekiq/testing"

RSpec.describe Notification do
  include ActiveSupport::Testing::TimeHelpers

  let(:user)            { create(:user, :without_profile, profile_image: nil) }
  let(:user2)           { create(:user, :without_profile, profile_image: nil) }
  let(:user3)           { create(:user, :without_profile, profile_image: nil) }
  let(:organization)    { create(:organization) }
  let(:article) do
    create(:article, :with_notification_subscription, user: user, with_tags: false, with_main_image: false,
                                                      page_views_count: 4000, public_reactions_count: 70)
  end
  let(:user_follows_user2) { user.follow(user2) }
  let(:comment) { create(:comment, user: user2, commentable: article) }
  let(:badge_achievement) { build_stubbed(:badge_achievement) }

  it "validates a unique user_id according to the correct scope" do
    notification = create(:notification, user: user2, notifiable: article, organization: nil)

    scopes = %i[organization_id notifiable_id notifiable_type action]
    expect(notification).to validate_uniqueness_of(:user_id).scoped_to(scopes)
  end

  describe "when trying to create duplicate notifications" do
    describe "when notifiable is an Article" do
      it "doesn't allow to create duplicated article reaction notifications for a user" do
        reaction = create(:reaction, reactable: article, user: user2)

        described_class.send_reaction_notification_without_delay(reaction, article.user)
        expect(article.user.notifications.count).to eq(1)

        expect do
          described_class.send_reaction_notification_without_delay(reaction, article.user)
        end.not_to change(article.user.notifications, :count)
      end

      it "doesn't allow to create duplicated article reaction notifications for an organization" do
        article.update_column(:organization_id, organization.id)
        reaction = create(:reaction, reactable: article, user: user2)

        described_class.send_reaction_notification_without_delay(reaction, article.organization)
        expect(article.organization.notifications.count).to eq(1)

        expect do
          described_class.send_reaction_notification_without_delay(reaction, article.organization)
        end.not_to change(article.organization.notifications, :count)
      end
    end

    describe "when notifiable is a Comment" do
      it "doesn't allow to create duplicated comment reaction notifications for a user" do
        reaction = create(:reaction, reactable: comment, user: user)

        described_class.send_reaction_notification_without_delay(reaction, comment.user)
        expect(comment.user.notifications.count).to eq(1)

        expect do
          described_class.send_reaction_notification_without_delay(reaction, comment.user)
        end.not_to change(comment.user.notifications, :count)
      end

      it "doesn't allow to create duplicated comment reaction notifications for an organization" do
        article.update_column(:organization_id, organization.id)
        reaction = create(:reaction, reactable: comment, user: user)

        described_class.send_reaction_notification_without_delay(reaction, article.organization)
        expect(article.organization.notifications.count).to eq(1)

        expect do
          described_class.send_reaction_notification_without_delay(reaction, article.organization)
        end.not_to change(article.organization.notifications, :count)
      end
    end
  end

  context "when callbacks are triggered after create" do
    it "sets the notified_at column" do
      notification = create(:notification, notifiable: article, user: user2, organization: nil)
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
      it "creates a notification belonging to the person being followed from the follow instance",
         :aggregate_failures do
        expect do
          sidekiq_perform_enqueued_jobs(only: Notifications::NewFollowerWorker) do
            described_class.send_new_follower_notification(user_follows_user2)
          end
        end.to change(user2.notifications, :count).by(1)

        notification = user2.notifications.last
        notifiable_data = { notifiable_id: notification.notifiable_id, notifiable_type: notification.notifiable_type }
        follow_data = { notifiable_id: user_follows_user2.id, notifiable_type: user_follows_user2.class.name }
        expect(notifiable_data).to eq(follow_data)
      end

      it "sends as perform_in 60 minutes if follower is new" do
        user.update_column(:registered_at, 1.day.ago)
        allow(Notifications::NewFollowerWorker).to receive(:perform_in)
          .with(60.minutes, anything, anything)
        described_class.send_new_follower_notification(user_follows_user2)
        expect(Notifications::NewFollowerWorker).to have_received(:perform_in)
          .with(60.minutes, anything, anything)
      end

      it "sends as perform_async if follower is not new" do
        user.update_column(:registered_at, 7.days.ago)
        allow(Notifications::NewFollowerWorker).to receive(:perform_async)
          .with(anything, anything)
        described_class.send_new_follower_notification(user_follows_user2)
        expect(Notifications::NewFollowerWorker).to have_received(:perform_async)
      end
    end

    context "when a user follows an organization" do
      let(:user_follows_organization) { user.follow(organization) }

      it "creates an organization notification from the follow instance without setting user_id",
         :aggregate_failures do
        expect do
          sidekiq_perform_enqueued_jobs(only: Notifications::NewFollowerWorker) do
            described_class.send_new_follower_notification(user_follows_organization)
          end
        end.to change(organization.notifications, :count).by(1)

        notification = organization.notifications.last
        expect(notification.user_id).to be_nil
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
    let(:child_comment) { create(:comment, user: user3, commentable: article, parent: comment) }

    context "when all commenters are subscribed" do
      it "notifies the article author and does not notify the comment author" do
        expect do
          described_class.send_new_comment_notifications_without_delay(comment)
        end.to change(user.notifications, :count).by(1)
          .and not_change(user2.notifications, :count)
      end

      it "does not send a notification to the author of the article if the commenter is the author" do
        author_comment = create(:comment, user: user, commentable: article)
        expect do
          described_class.send_new_comment_notifications_without_delay(author_comment)
        end.not_to change(user.notifications, :count)
      end

      it "sends a notification to the author of the article about the child comment" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.to change(user.notifications, :count).by(1)
      end

      it "sends a notification to the organization" do
        create(:organization_membership, user: user, organization: organization)
        article.update(organization: organization)

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
        end.not_to change(user.notifications, :count)
      end

      it "doesn't send a notification to the author of the article about the child comment" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.not_to change(user.notifications, :count)
      end
    end

    context "when the author of a comment is not subscribed" do
      before do
        comment.update(receive_notifications: false)
      end

      it "does not send a notification to the author of the comment" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.not_to change(child_comment.user.notifications, :count)
      end

      it "sends a notification to the author of the article" do
        expect do
          described_class.send_new_comment_notifications_without_delay(child_comment)
        end.to change(user.notifications, :count).by(1)
      end
    end
  end

  describe "#send_reaction_notification" do
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
        user4.destroy

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_reaction_notification(reaction, reaction.reactable.user)
          end
        end.not_to change(article.user.notifications, :count)
      end
    end

    context "when a reaction is destroyed" do
      let!(:notification) do
        create(:notification, user: user, organization: nil, notifiable: comment, action: "Reaction")
      end
      let(:sibling_reaction) { create(:reaction, reactable: comment, user: user3) }

      it "destroys the notification if it exists" do
        reaction = create(:reaction, reactable: comment, user: user)
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        expect(described_class.exists?(id: notification.id)).to be(false)
      end

      it "keeps the notification and omits the destroyed reaction data if siblings exist", :aggregate_failures do
        reaction = create(:reaction, reactable: comment, user: user)
        sibling_reaction # to create it
        reaction.destroy
        described_class.send_reaction_notification_without_delay(reaction, article.user)
        notification.reload
        expect(notification).to be_persisted
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
        end.not_to change(user.notifications, :count)
      end

      it "does send a notification to the author of an article" do
        article.update(receive_notifications: false)
        reaction = create(:reaction, reactable: article, user: user2)

        expect do
          described_class.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        end.to change(user.notifications, :count).by(1)
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
        end.not_to change(article.notifications, :count)
      end
    end
  end

  def status_article?(article)
    article.type_of == "status"
  end

  describe "send_to_mentioned_users_and_followers" do
    let(:mention_markdown) { "Hello there, @#{user2.username}!" }

    context "when the notifiable is an article from a user" do
      before do
        article.update!(body_markdown: mention_markdown)
        user2.follow(user)
      end

      it "notifies mentioned followers via Mention and unmentioned followers via Article", :aggregate_failures do
        article.update!(type_of: "full_post") # ensure it's not a status
        user3.follow(user)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_mentioned_users_and_followers(article) unless status_article?(article)
          end
        end.to change(user2.notifications, :count).from(0).to(1)
          .and change(user3.notifications, :count).from(0).to(1)
        expect(user2.notifications.first.notifiable_type).to eq("Mention")
        expect(user3.notifications.first.notifiable_type).to eq("Article")
      end

      it "does not send a notification to mentioned user if article is of type status" do
        article.update_column(:type_of, "status")
        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_mentioned_users_and_followers(article) unless status_article?(article)
          end
        end.not_to change(user2.notifications, :count)
      end
    end
  end

  describe "#send_to_followers" do
    context "when the notifiable is an article from a user" do
      it "sends a notification to the author's followers if article is not status" do
        article.update!(type_of: "full_post") # ensure it's not a status
        user2.follow(user)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_followers(article, "Published") unless status_article?(article)
          end
        end.to change(user2.notifications, :count).by(1)
      end

      it "does not send a notification to the author's followers if article is of type status" do
        article.update_column(:type_of, "status")
        user2.follow(user)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_followers(article, "Published") unless status_article?(article)
          end
        end.not_to change(user2.notifications, :count)
      end
    end

    context "when the notifiable is an article from an organization" do
      let(:org_article) { create(:article, organization: organization, user: user, with_tags: false) }

      it "sends notifications to the author's and organization's followers if article is not status" do
        org_article.update!(type_of: "full_post") # ensure it's not a status
        user2.follow(user)
        user3.follow(organization)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_followers(org_article, "Published") unless status_article?(org_article)
          end
        end.to change(user2.notifications, :count).by(1)
          .and change(user3.notifications, :count).by(1)
      end

      it "does not send notifications to the author's or organization's followers if article is of type status" do
        org_article.update_column(:type_of, "status")
        user2.follow(user)
        user3.follow(organization)

        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.send_to_followers(org_article, "Published") unless status_article?(org_article)
          end
        end.to not_change(user2.notifications, :count)
          .and not_change(user3.notifications, :count)
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
        new_body_markdown = article.body_markdown.gsub(article.title, new_title)
        article.update(title: new_title, body_markdown: new_body_markdown)
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

      it "updates CoAuthor notifications with the new article title" do
        article.update(co_author_ids: [user3.id])
        sidekiq_perform_enqueued_jobs { described_class.send_to_co_authors(article) }

        new_title = "Brand New Co-Authored Title"
        new_body_markdown = article.body_markdown.gsub(article.title, new_title)
        article.update(title: new_title, body_markdown: new_body_markdown)
        described_class.update_notifications(article, %w[Published CoAuthor])
        sidekiq_perform_enqueued_jobs

        co_author_notification = user3.notifications.find_by(action: "CoAuthor")
        expect(co_author_notification.json_data["article"]["title"]).to eq(new_title)
      end
    end
  end

  describe "#aggregated?" do
    let(:notification) { described_class.new }

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
      create(:notification, user: mention.user, organization: nil, notifiable: mention)

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
      described_class.fast_destroy_old_notifications(10.days.ago)
      expect(BulkSqlDelete).to have_received(:delete_in_batches).with(/</)
    end

    it "uses an 85 day retention window by default" do
      freeze_time do
        allow(BulkSqlDelete).to receive(:delete_in_batches)
        allow(described_class).to receive(:sanitize_sql).and_call_original

        described_class.fast_destroy_old_notifications

        expect(described_class).to have_received(:sanitize_sql).with(array_including(85.days.ago))
      end
    end
  end

  describe ".fast_cleanup_older_than_100_for" do
    it "bulk deletes comment and non-comment notifications older than 100 for a user" do
      allow(BulkSqlDelete).to receive(:delete_in_batches)
      described_class.fast_cleanup_older_than_100_for(user.id)
      expect(BulkSqlDelete).to have_received(:delete_in_batches).twice
    end

    it "actually deletes the excessive notifications" do
      now = Time.current
      base = ->(i) { { user_id: user.id, notifiable_id: i, created_at: now - i.minutes, updated_at: now - i.minutes } }
      comments_data = Array.new(105) { |i| base.call(i).merge(notifiable_type: "Comment") }
      reactions_data = Array.new(105) { |i| base.call(i).merge(action: "Reaction", notifiable_type: "Article") }

      described_class.insert_all!(comments_data)
      described_class.insert_all!(reactions_data)

      described_class.fast_cleanup_older_than_100_for(user.id)

      expect(user.notifications.where(notifiable_type: "Comment").count).to eq(100)
      expect(user.notifications.where("notifiable_type != 'Comment' OR notifiable_type IS NULL").count).to eq(100)
    end
  end

  describe "#cleanup_old_notifications" do
    let(:notification) { described_class.new(user_id: 1) }

    after do
      Rails.cache.delete("cleanup_user_notifications_1")
    end

    context "when ENABLE_USER_NOTIFICATION_CLEANUP is not set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ENABLE_USER_NOTIFICATION_CLEANUP").and_return(nil)
      end

      it "does not enqueue a cleanup job" do
        allow(notification).to receive(:rand).with(10).and_return(0)

        expect do
          notification.__send__(:cleanup_old_notifications)
        end.not_to change(Notifications::CleanupUserWorker.jobs, :size)
      end
    end

    context "when ENABLE_USER_NOTIFICATION_CLEANUP is true" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ENABLE_USER_NOTIFICATION_CLEANUP").and_return("true")
      end

      it "enqueues a cleanup job 10% of the time and throttles via cache" do
        allow(notification).to receive(:rand).with(10).and_return(0)

        expect do
          notification.__send__(:cleanup_old_notifications)
        end.to change(Notifications::CleanupUserWorker.jobs, :size).by(1)

        allow(Rails.cache).to receive(:write)
          .with("cleanup_user_notifications_1", 1, expires_in: 10.minutes, unless_exist: true)
          .and_return(false)

        expect do
          notification.__send__(:cleanup_old_notifications)
        end.not_to change(Notifications::CleanupUserWorker.jobs, :size)
      end

      it "does not enqueue a cleanup job 90% of the time" do
        allow(notification).to receive(:rand).with(10).and_return(1)

        expect do
          notification.__send__(:cleanup_old_notifications)
        end.not_to change(Notifications::CleanupUserWorker.jobs, :size)
      end
    end
  end

  describe ".send_to_co_authors" do
    before do
      allow(Notifications::CoAuthorWorker).to receive(:perform_async)
    end

    it "enqueues CoAuthorWorker when co_author_ids are present" do
      stubbed_article = build_stubbed(:article, co_author_ids: [1])
      described_class.send_to_co_authors(stubbed_article)

      expect(Notifications::CoAuthorWorker).to have_received(:perform_async).with(stubbed_article.id, [])
    end

    it "enqueues CoAuthorWorker when removed_user_ids are present even if co_author_ids is empty" do
      stubbed_article = build_stubbed(:article, co_author_ids: [])
      described_class.send_to_co_authors(stubbed_article, [1])

      expect(Notifications::CoAuthorWorker).to have_received(:perform_async).with(stubbed_article.id, [1])
    end

    it "skips enqueuing when both co_author_ids and removed_user_ids are blank" do
      stubbed_article = build_stubbed(:article, co_author_ids: [])
      described_class.send_to_co_authors(stubbed_article, [])

      expect(Notifications::CoAuthorWorker).not_to have_received(:perform_async)
    end

    it "skips enqueuing when notifiable is not an Article" do
      described_class.send_to_co_authors(build_stubbed(:comment), [1])

      expect(Notifications::CoAuthorWorker).not_to have_received(:perform_async)
    end
  end

  describe ".for_published_articles" do
    it "includes both Published and CoAuthor notifications" do
      attrs = { user: user, organization: nil, notifiable: article }
      published_notification = create(:notification, **attrs, action: "Published")
      co_author_notification = create(:notification, **attrs, action: "CoAuthor")
      _other_notification = create(:notification, **attrs, action: "Moderation")

      expect(described_class.for_published_articles).to contain_exactly(published_notification, co_author_notification)
    end
  end
end
