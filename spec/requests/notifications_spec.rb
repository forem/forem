require "rails_helper"

RSpec.describe "NotificationsIndex", type: :request do
  include ActionView::Helpers::DateHelper

  let(:dev_account) { create(:user) }
  let(:mascot_account) { create(:user) }
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    allow(User).to receive(:dev_account).and_return(dev_account)
    allow(User).to receive(:mascot_account).and_return(mascot_account)
  end

  def has_both_names(response_body)
    response_body.include?(CGI.escapeHTML(User.last.name)) &&
      response_body.include?(CGI.escapeHTML(User.second_to_last.name))
  end

  def renders_article_path(article)
    expect(response.body).to include article.path
  end

  def renders_comments_html(comment)
    expect(response.body).to include comment.processed_html
  end

  describe "GET /notifications" do
    it "renders page with the proper heading" do
      get "/notifications"
      expect(response.body).to include("Notifications")
    end

    context "when signed out" do
      it "renders the signup page" do
        get "/notifications"

        expect(response.body).to include("Continue with")
      end
    end

    context "when signed in" do
      it "does not render the signup cue" do
        sign_in user

        get "/notifications"
        expect(response.body).not_to include("Continue with")
      end
    end

    context "when a user has new follow notifications" do
      before { sign_in user }

      def mock_follow_notifications(amount)
        create_list :user, amount
        follow_instances = User.last(amount).map { |follower| follower.follow(user) }
        follow_instances.each { |follow| Notification.send_new_follower_notification_without_delay(follow) }
      end

      it "renders the proper message for a single notification" do
        mock_follow_notifications(1)
        get "/notifications"
        expect(response.body).to include CGI.escapeHTML(User.last.name)
      end

      it "renders the proper message for two notifications in the same day" do
        mock_follow_notifications(2)
        get "/notifications"
        expect(has_both_names(response.body)).to be true
      end

      it "renders the proper message for three or more notifications in the same day" do
        mock_follow_notifications(rand(3..10))
        get "/notifications"
        follow_message = "others followed you!"
        expect(response.body).to include follow_message
      end

      it "does group notifications that occur on different days" do
        mock_follow_notifications(2)
        Notification.last.update(created_at: Notification.last.created_at - 1.day)
        get "/notifications"
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq 1
      end
    end

    context "when a user's organization has new follow notifications" do
      let(:other_org) { create(:organization) }

      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        sign_in user
      end

      def mock_follow_notifications(followers_amount, organization)
        users = create_list(:user, followers_amount)
        follow_instances = users.map { |follower| follower.follow(organization) }
        follow_instances.each { |follow| Notification.send_new_follower_notification_without_delay(follow) }
        users
      end

      it "renders the proper message for a single notification" do
        users = mock_follow_notifications(1, organization)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include(CGI.escapeHTML(users.last.name))
      end

      it "renders the proper message for two notifications in the same day" do
        mock_follow_notifications(2, organization)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(has_both_names(response.body)).to be(true)
      end

      it "renders the proper message for three or more notifications in the same day" do
        mock_follow_notifications(rand(3..5), organization)

        get notifications_path(filter: :org, org_id: organization.id)
        follow_message = "others followed you!"
        expect(response.body).to include(follow_message)
      end

      it "does group notifications that occur on different days" do
        mock_follow_notifications(2, organization)
        Notification.last.update(created_at: Notification.last.created_at - 1.day)

        get notifications_path(filter: :org, org_id: organization.id)
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq(1)
      end

      it "does not render the proper message for a single notification if missing :org_id" do
        users = mock_follow_notifications(1, organization)

        get notifications_path(filter: :org)
        expect(response.body).not_to include(CGI.escapeHTML(users.last.name))
      end

      it "does not render notifications belonging to other orgs" do
        users = mock_follow_notifications(1, other_org)

        get notifications_path(filter: :org, org_id: other_org.id)
        expect(response.body).not_to include(CGI.escapeHTML(users.last.name))
      end

      it "does render notifications belonging to other orgs if admin" do
        user.add_role(:super_admin)
        sign_in user

        users = mock_follow_notifications(1, other_org)

        get notifications_path(filter: :org, org_id: other_org.id)
        expect(response.body).to include(CGI.escapeHTML(users.last.name))
      end

      it "does not render the proper message for a single notification if :filter is comments" do
        users = mock_follow_notifications(1, organization)

        get notifications_path(filter: :comments, org_id: organization.id)
        expect(response.body).not_to include(CGI.escapeHTML(users.last.name))
      end
    end

    context "when a user has new reaction notifications" do
      let(:article1)                   { create(:article, user_id: user.id) }
      let(:article2)                   { create(:article, user_id: user.id) }
      let(:special_characters_article) { create(:article, user_id: user.id, title: "What's Become of Waring") }

      before { sign_in user }

      def mock_heart_reaction_notifications(amount, categories, reactable = article1)
        create_list :user, amount
        reactions = User.last(amount).map do |user|
          create(
            :reaction,
            user_id: user.id,
            reactable_id: reactable.id,
            reactable_type: reactable.class.name,
            category: categories.sample,
          )
        end
        reactions.each do |reaction|
          Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
        end
      end

      it "renders the correct user for a single reaction" do
        mock_heart_reaction_notifications(1, %w[like unicorn])
        get "/notifications"
        expect(response.body).to include CGI.escapeHTML(User.last.name)
      end

      it "renders the correct usernames for two or more reactions" do
        mock_heart_reaction_notifications(2, %w[like unicorn])
        get "/notifications"
        expect(has_both_names(response.body)).to be true
      end

      it "renders the proper message for multiple reactions" do
        random_amount = rand(3..10)
        mock_heart_reaction_notifications(random_amount, %w[unicorn like])
        get "/notifications"
        expect(response.body).to include CGI.escapeHTML("and #{random_amount - 1} others")
      end

      it "does group notifications that are on different days but have the same reactable" do
        mock_heart_reaction_notifications(2, %w[unicorn like readinglist])
        Notification.last.update(created_at: Notification.last.created_at - 1.day)
        get "/notifications"
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq 1
      end

      it "does not group notifications that are on the same day but have different reactables" do
        mock_heart_reaction_notifications(1, %w[unicorn like readinglist], article1)
        mock_heart_reaction_notifications(1, %w[unicorn like readinglist], article2)
        get "/notifications"
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq 2
      end

      it "properly renders reactable titles" do
        mock_heart_reaction_notifications(1, %w[unicorn like readinglist], special_characters_article)
        get "/notifications"
        expect(response.body).to include ERB::Util.html_escape(special_characters_article.title)
      end

      it "properly renders reactable titles for multiple reactions" do
        amount = rand(3..10)
        mock_heart_reaction_notifications(amount, %w[unicorn like readinglist], special_characters_article)
        get "/notifications"
        expect(response.body).to include ERB::Util.html_escape(special_characters_article.title)
      end
    end

    context "when a user's organization has new reaction notifications" do
      let(:article1) { create(:article, user: user, organization: organization) }
      let(:article2) { create(:article, user: user, organization: organization) }
      let(:special_characters_article) do
        create(:article, user: user, organization: organization, title: "What's Become of Waring")
      end
      let(:other_org) { create(:organization) }
      let(:other_org_article) { create(:article, user: user, organization: other_org) }

      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        sign_in user
      end

      def mock_heart_reaction_notifications(followers_amount, categories, reactable = article1)
        users = create_list(:user, followers_amount)

        reactions = users.map do |user|
          create(:reaction, user: user, reactable: reactable, category: categories.sample)
        end
        reactions.each do |reaction|
          Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.organization)
        end

        users
      end

      it "renders the correct user for a single reaction" do
        users = mock_heart_reaction_notifications(1, %w[like unicorn])

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include CGI.escapeHTML(users.last.name)
      end

      it "renders the correct usernames for two or more reactions" do
        mock_heart_reaction_notifications(2, %w[like unicorn])

        get notifications_path(filter: :org, org_id: organization.id)
        expect(has_both_names(response.body)).to be(true)
      end

      it "renders the proper message for multiple reactions" do
        random_amount = rand(3..10)
        mock_heart_reaction_notifications(random_amount, %w[unicorn like])

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include(CGI.escapeHTML("and #{random_amount - 1} others"))
      end

      it "does group notifications that are on different days but have the same reactable" do
        mock_heart_reaction_notifications(2, %w[unicorn like readinglist])
        Notification.last.update(created_at: Notification.last.created_at - 1.day)

        get notifications_path(filter: :org, org_id: organization.id)
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq(1)
      end

      it "does not group notifications that are on the same day but have different reactables" do
        mock_heart_reaction_notifications(1, %w[unicorn like readinglist], article1)
        mock_heart_reaction_notifications(1, %w[unicorn like readinglist], article2)

        get notifications_path(filter: :org, org_id: organization.id)
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq(2)
      end

      it "properly renders reactable titles" do
        mock_heart_reaction_notifications(1, %w[unicorn like readinglist], special_characters_article)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include(ERB::Util.html_escape(special_characters_article.title))
      end

      it "properly renders reactable titles for multiple reactions" do
        amount = rand(3..10)
        mock_heart_reaction_notifications(amount, %w[unicorn like readinglist], special_characters_article)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include(ERB::Util.html_escape(special_characters_article.title))
      end

      it "does not render the proper message for a single notification if missing :org_id" do
        users = mock_heart_reaction_notifications(1, %w[like unicorn])

        get notifications_path(filter: :org)
        expect(response.body).not_to include(CGI.escapeHTML(users.last.name))
      end

      it "does not render notifications belonging to other orgs" do
        users = mock_heart_reaction_notifications(1, %w[like unicorn], other_org_article)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).not_to include(CGI.escapeHTML(users.last.name))
      end

      it "does render notifications belonging to other orgs if admin" do
        user.add_role(:super_admin)
        sign_in user

        users = mock_heart_reaction_notifications(1, %w[like unicorn], other_org_article)

        get notifications_path(filter: :org, org_id: other_org_article.organization_id)
        expect(response.body).to include(CGI.escapeHTML(users.last.name))
      end

      it "does not render the proper message for a single notification if :filter is comments" do
        users = mock_heart_reaction_notifications(1, %w[like unicorn])

        get notifications_path(filter: :comments, org_id: organization.id)
        expect(response.body).not_to include(CGI.escapeHTML(users.last.name))
      end
    end

    context "when a user has a new comment notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, :with_notification_subscription, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        sign_in user
        Notification.send_new_comment_notifications_without_delay(comment)
        get "/notifications"
      end

      it "renders the correct message data", :aggregate_failures do
        expect(response.body).to include "commented on"
        expect(response.body).not_to include "replied to a thread in"
        expect(response.body).not_to include "As a trusted member"
        renders_article_path(article)
        renders_comments_html(comment)
        does_not_render_reaction
      end

      def does_not_render_reaction
        expect(response.body).not_to include "reaction-button reacted"
      end

      it "renders the reaction as previously reacted if it was reacted on" do
        Reaction.create(user: user, reactable: comment, category: "like")
        get "/notifications"
        expect(response.body).to include "reaction-button reacted"
      end
    end

    context "when a user's organization has a new comment notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, :with_notification_subscription, user: user, organization: organization) }
      let(:comment)  { create(:comment, user: user2, commentable: article) }
      let(:other_org) { create(:organization) }
      let(:other_org_article) { create(:article, :with_notification_subscription, user: user, organization: other_org) }
      let(:other_org_comment) { create(:comment, user: user2, commentable: other_org_article) }

      before do
        sign_in user
      end

      it "renders the correct message data", :aggregate_failures do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include("commented on")
        expect(response.body).not_to include("replied to a thread in")
        expect(response.body).not_to include("As a trusted member")
        renders_article_path(article)
        renders_comments_html(comment)
      end

      it "renders the reaction as previously reacted if it was reacted on" do
        Notification.send_new_comment_notifications_without_delay(comment)
        Reaction.create(user: user, reactable: comment, category: "like")

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include("reaction-button reacted")
      end

      it "does not render the reaction as reacted if it was not reacted on" do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).not_to include("reaction-button reacted")
      end

      it "does not render notifications if missing :org_id" do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :org)
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.filter_map(&:organization_id).size).to eq(0)
      end

      it "does not render notifications belonging to other orgs" do
        Notification.send_new_comment_notifications_without_delay(other_org_comment)

        get notifications_path(filter: :org, org_id: other_org.id)
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.map(&:organization_id).compact.size).to eq(0)
      end

      it "does render notifications belonging to other orgs if admin" do
        user.add_role(:super_admin)
        sign_in user

        Notification.send_new_comment_notifications_without_delay(other_org_comment)

        get notifications_path(filter: :org, org_id: other_org.id)
        expect(response.body).to include("commented on")
      end

      it "does render the proper message for a single notification if :filter is comments" do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :comments, org_id: organization.id)
        expect(response.body).to include("commented on")
      end
    end

    context "when a user has a new second level comment notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, :with_notification_subscription, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }
      let(:second_comment) do
        create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article",
                         parent_id: comment.id)
      end
      let(:third_comment) do
        create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article",
                         parent_id: second_comment.id)
      end

      before do
        sign_in user
        Notification.send_new_comment_notifications_without_delay(comment)
        Notification.send_new_comment_notifications_without_delay(second_comment)
        Notification.send_new_comment_notifications_without_delay(third_comment)
        get "/notifications"
      end

      it "renders comment notification text properly", :aggregate_failures do
        expect(response.body).to include "replied to a thread in"
        expect(response.body).to include CGI.escapeHTML("Re")
        expect(response.body).to include CGI.escapeHTML(comment.title.to_s)
      end
    end

    context "when a user has a new moderation notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        user.add_role(:trusted)
        sign_in user
        sidekiq_perform_enqueued_jobs do
          Notification.send_moderation_notification(comment)
        end
        get "/notifications"
      end

      it "renders the proper message data", :aggregate_failures do
        expect(response.body).to include "Since they are new to the community, could you leave a nice reply"
        renders_article_path(article)
        renders_comments_html(comment)
      end
    end

    context "when a user should not receive moderation notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        sign_in user
        sidekiq_perform_enqueued_jobs do
          Notification.send_moderation_notification(comment)
        end
        get "/notifications"
      end

      it "does not render the notification message", :aggregate_failures do
        expect(response.body).not_to include "Since they are new to the community, could you leave a nice reply"
        expect(response.body).not_to include article.path
        expect(response.body).not_to include comment.processed_html
      end
    end

    context "when a user has unsubscribed from mod roundrobin notifications" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        user.add_role(:trusted)
        user.update(mod_roundrobin_notifications: false)
        sign_in user
        sidekiq_perform_enqueued_jobs do
          Notification.send_moderation_notification(comment)
        end
        get "/notifications"
      end

      it "does not render the proper message", :aggregate_failures do
        expect(response.body).not_to include "Since they are new to the community, could you leave a nice reply"
        expect(response.body).not_to include article.path
        expect(response.body).not_to include comment.processed_html
      end
    end

    context "when user is trusted" do
      let(:user) { create(:user, :trusted) }
      let(:reaction) { create(:thumbsdown_reaction, user: user) }
      let(:like_reaction) { create(:reaction, user: user) }

      it "allow sees thumbsdown category" do
        sign_in user
        Notification.send_reaction_notification_without_delay(reaction, user)
        get "/notifications"
        expect(response.body).to include("Notifications")
      end

      it "does not show notification" do
        other_user = create(:user)
        sign_in other_user
        Notification.send_reaction_notification_without_delay(reaction, other_user)
        Notification.send_reaction_notification_without_delay(like_reaction, other_user)
        get "/notifications"
        expect(response.body).to include("Like")
        expect(response.body).not_to include("Thumbsdown")
      end
    end

    context "when a user has a new welcome notification" do
      let(:active_broadcast) { create(:set_up_profile_broadcast) }
      let(:inactive_broadcast) { create(:set_up_profile_broadcast, active: false) }

      before { sign_in user }

      it "renders a welcome notification if the broadcast is active" do
        sidekiq_perform_enqueued_jobs do
          Notification.send_welcome_notification(user.id, active_broadcast.id)
        end
        get "/notifications"
        expect(response.body).to include active_broadcast.processed_html
      end

      it "does not render a welcome notification if the broadcast is inactive" do
        sidekiq_perform_enqueued_jobs do
          Notification.send_welcome_notification(user.id, inactive_broadcast.id)
        end
        get "/notifications"
        expect(response.body).not_to include inactive_broadcast.processed_html
      end
    end

    context "when a user has a new badge notification" do
      before do
        sign_in user
        badge = create(:badge)
        badge_achievement = create(:badge_achievement, user: user, badge: badge)
        sidekiq_perform_enqueued_jobs do
          Notification.send_new_badge_achievement_notification(badge_achievement)
        end
        get "/notifications"
      end

      it "renders the correct badge's notification", :aggregate_failures do
        renders_title
        renders_correct_message(user)
        renders_correct_description
        renders_visit_profile_button
      end

      def renders_title
        expect(response.body).to include Badge.first.title
      end

      def renders_correct_message(user)
        expect(response.body).to include user.badge_achievements.first.rewarding_context_message
      end

      def renders_correct_description
        expect(response.body).to include CGI.escapeHTML(Badge.first.description)
      end

      def renders_visit_profile_button
        expect(response.body).to include "Visit your profile"
      end
    end

    context "when a user has a new mention notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment) do
        create(
          :comment,
          user_id: user2.id,
          commentable_id: article.id,
          commentable_type: "Article",
          body_markdown: "@#{user.username}",
        )
      end
      let(:mention) { create(:mention, mentionable: comment, user: user) }

      before do
        sidekiq_perform_enqueued_jobs do
          Notification.send_mention_notification(mention)
        end
        sign_in user
        get "/notifications"
      end

      it "renders the proper message" do
        expect(response.body).to include "mentioned you in a comment"
        renders_comments_html(comment)
      end
    end

    context "when a user has a new article notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }

      before do
        user2.follow(user)
        sidekiq_perform_enqueued_jobs do
          Notification.send_to_followers(article, "Published")
        end
        sign_in user2
        get "/notifications"
      end

      it "renders the proper message", :aggregate_failures do
        expect(response.body).to include "made a new post"
        renders_article_path(article)
        renders_authors_name(article)
        renders_article_published_at(article)
      end

      def renders_authors_name(article)
        expect(response.body).to include CGI.escapeHTML(article.user.name)
      end

      def renders_article_published_at(article)
        expect(response.body).to include time_ago_in_words(article.published_at)
      end

      it "renders the reaction as previously reacted if it was reacted on" do
        Reaction.create(user: user2, reactable: article, category: "like")
        get "/notifications"
        expect(response.body).to include "reaction-button reacted"
      end

      it "does not render the reaction as reacted if it was not reacted on" do
        expect(response.body).not_to include "reaction-button reacted"
      end
    end

    context "when a user is an admin" do
      let(:admin) { create(:user, :super_admin) }
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }

      before do
        user2.follow(user)
        sidekiq_perform_enqueued_jobs do
          Notification.send_to_followers(article, "Published")
        end
        sign_in admin
      end

      it "can view other people's notifications" do
        get "/notifications?username=#{user2.username}"
        expect(response.body).to include "made a new post"
      end
    end

    context "when filter is unknown" do
      it "does not raise an error" do
        sign_in user
        expect { get "/notifications/feed" }.not_to raise_error
      end
    end
  end
end
