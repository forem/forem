require "rails_helper"

RSpec.describe "NotificationsIndex", type: :request do
  let(:user) { create(:user) }

  describe "GET notifications" do
    it "renders page with the proper heading" do
      get "/notifications"
      expect(response.body).to include("Notifications")
    end

    context "when signed out" do
      it "renders the signup cue" do
        get "/notifications"
        expect(response.body).to include "<div class=\"signup-cue"
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "does not render the signup cue" do
        get "/notifications"
        expect(response.body).not_to include "Create your account"
      end
    end

    context "when a user has new follow notifications" do
      before do
        sign_in user
      end

      def mock_follow_notifications(amount)
        create_list :user, amount
        follow_instances = User.last(amount).map { |follower| follower.follow(user) }
        follow_instances.each { |follow| Notification.send_new_follower_notification_without_delay(follow) }
      end

      it "renders the proper message for a single notification" do
        mock_follow_notifications(1)
        get "/notifications"
        follow_message = "#{User.last.name}</a> followed you!"
        expect(response.body).to include follow_message
      end

      it "renders the proper message for two notifications in the same day" do
        mock_follow_notifications(2)
        get "/notifications"
        follow_message = "#{CGI.escapeHTML(User.last.name)}</a> and\n        <a href=\"/#{CGI.escapeHTML(User.second_to_last.username)}\">#{CGI.escapeHTML(User.second_to_last.name)}</a> followed you!"
        expect(response.body).to include CGI.escapeHTML(follow_message)
      end

      it "renders the proper message for three or more notifications in the same day" do
        mock_follow_notifications(rand(3..10))
        get "/notifications"
        follow_message = "others followed you!"
        expect(response.body).to include follow_message
      end

      it "groups two notifications on the same day" do
        mock_follow_notifications(2)
        get "/notifications"
        grouped_notifications = controller.instance_variable_get(:@notifications)[0].grouped_notifications
        # only one notification object containing a group of notifications
        expect(grouped_notifications.count).to eq 2
      end

      it "groups three or more notifications on the same day" do
        amount = rand(3..10)
        mock_follow_notifications(amount)
        get "/notifications"
        grouped_notifications = controller.instance_variable_get(:@notifications)[0].grouped_notifications
        expect(grouped_notifications.count).to eq amount
      end

      it "does not group notifications that occur on different days" do
        mock_follow_notifications(2)
        Notification.last.update(created_at: Notification.last.created_at - 1.day)
        get "/notifications"
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq 2
      end
    end

    context "when a user has new reaction notifications" do
      let(:article1)                   { create(:article, user_id: user.id) }
      let(:article2)                   { create(:article, user_id: user.id) }
      let(:special_characters_article) { create(:article, user_id: user.id, title: "Nothing like good ol' blah blah blah") }

      before do
        sign_in user
      end

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
        reactions.each { |reaction| Notification.send_reaction_notification_without_delay(reaction) }
      end

      it "renders the proper message for a single public reaction" do
        mock_heart_reaction_notifications(1, %w(like unicorn))
        get "/notifications"
        message = "#{CGI.escapeHTML(User.last.name)}</strong></a> reacted to"
        expect(response.body).to include message
      end

      it "renders the proper message for a single private reaction" do
        mock_heart_reaction_notifications(1, %w(readinglist))
        get "/notifications"
        message = "Someone reacted to"
        expect(response.body).to include message
      end

      it "renders the proper message for two or more public reactions" do
        mock_heart_reaction_notifications(2, %w(like unicorn))
        get "/notifications"
        message = "#{User.last.name}</a> and <a href=\"/#{CGI.escapeHTML(User.second_to_last.username)}\">#{CGI.escapeHTML(User.second_to_last.name)}</a>\n    reacted to"
        expect(response.body).to include CGI.escapeHTML(message)
      end

      it "renders the proper message for two or more reactions where at least one is private" do
        mock_heart_reaction_notifications(1, %w(readinglist))
        mock_heart_reaction_notifications(1, %w(unicorn like))
        get "/notifications"
        message = "Devs\n    reacted to"
        expect(response.body).to include CGI.escapeHTML(message)
      end

      it "renders the proper message for multiple public reactions" do
        mock_heart_reaction_notifications(3, %w(unicorn like))
        get "/notifications"
        message = "#{User.last.name}</a> and 2 others\n    reacted to"
        expect(response.body).to include CGI.escapeHTML(message)
      end

      it "properly groups two notifications that have the same day and reactable" do
        mock_heart_reaction_notifications(2, %w(unicorn like readinglist))
        get "/notifications"
        grouped_notifications = controller.instance_variable_get(:@notifications)[0].grouped_notifications
        expect(grouped_notifications.count).to eq 2
      end

      it "properly groups three or more notifications that have the same day and reactable" do
        amount = rand(3..10)
        mock_heart_reaction_notifications(amount, %w(unicorn like readinglist))
        get "/notifications"
        grouped_notifications = controller.instance_variable_get(:@notifications)[0].grouped_notifications
        expect(grouped_notifications.count).to eq amount
      end

      it "does not group notifications that are on different days but have the same reactable" do
        mock_heart_reaction_notifications(2, %w(unicorn like readinglist))
        Notification.last.update(created_at: Notification.last.created_at - 1.day)
        get "/notifications"
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq 2
      end

      it "does not group notifications that are on the same day but have different reactables" do
        mock_heart_reaction_notifications(1, %w(unicorn like readinglist), article1)
        mock_heart_reaction_notifications(1, %w(unicorn like readinglist), article2)
        get "/notifications"
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.count).to eq 2
      end

      it "properly renders reactable titles", focus: true do
        mock_heart_reaction_notifications(1, %w(unicorn like readinglist), special_characters_article)
        get "/notifications"
        expect(response.body).to include special_characters_article.title
      end

      it "properly renders reactable titles for multiple reactions", focus: true do
        amount = rand(3..10)
        mock_heart_reaction_notifications(amount, %w(unicorn like readinglist), special_characters_article)
        get "/notifications"
        expect(response.body).to include special_characters_article.title
      end
    end

    context "when a user has a new comment notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        sign_in user
        Notification.send_new_comment_notifications_without_delay(comment)
        get "/notifications"
      end

      it "renders the correct message" do
        expect(response.body).to include "commented on"
      end

      it "does not render the moderation message" do
        expect(response.body).not_to include "As a trusted member"
      end

      it "renders the original article's title" do
        expect(response.body).to include CGI.escapeHTML(article.title)
      end

      it "renders the comment's processed HTML" do
        expect(response.body).to include CGI.escapeHTML(comment.processed_html)
      end
    end

    context "when a user has a new moderation notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        user.update(id: 1)
        user.add_role :trusted
        sign_in user
        Notification.send_moderation_notification_without_delay(comment)
        get "/notifications"
      end

      it "renders the proper message" do
        expect(response.body).to include "As a trusted member"
      end

      it "renders the article's title" do
        expect(response.body).to include CGI.escapeHTML(article.title)
      end

      it "renders the comment's processed HTML" do
        expect(response.body).to include CGI.escapeHTML(comment.processed_html)
      end
    end

    context "when a user has a new welcome notification" do
      before do
        user.update(id: 1)
        sign_in user
      end

      it "renders the welcome notification" do
        broadcast = create(:broadcast, :onboarding)
        Notification.send_welcome_notification_without_delay(user.id)
        get "/notifications"
        expect(response.body).to include CGI.escapeHTML(broadcast.processed_html)
      end
    end

    context "when a user has a new badge notification" do
      before do
        sign_in user
        badge = create(:badge)
        badge_achievement = create(:badge_achievement, user: user, badge: badge)
        Notification.send_new_badge_notification_without_delay(badge_achievement)
        get "/notifications"
      end

      it "renders the proper message with the badge's title" do
        message = "You received the <strong>#{Badge.first.title}"
        expect(response.body).to include CGI.escapeHTML(message)
      end

      it "renders the rewarding context message" do
        expect(response.body).to include CGI.escapeHTML(user.badge_achievements.first.rewarding_context_message)
      end

      it "renders the badge's description" do
        expect(response.body).to include CGI.escapeHTML(Badge.first.description)
      end

      it "renders the CHECK YOUR PROFILE button" do
        expect(response.body).to include "CHECK YOUR PROFILE"
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

      before do
        user.update(id: 1)
        sign_in user
        comment
        Mention.create_all(comment)
        Notification.send_mention_notification_without_delay(Mention.first)
        get "/notifications"
      end

      it "renders the proper message" do
        expect(response.body).to include "mentioned you in a comment"
      end

      it "renders the processed HTML of the comment where they were mentioned" do
        expect(response.body).to include CGI.escapeHTML(comment.processed_html)
      end
    end

    context "when a user has a new article notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }

      before do
        user2.follow(user)
        Notification.send_to_followers_without_delay(article, "Published")
        sign_in user2
        get "/notifications"
      end

      it "renders the proper message" do
        expect(response.body).to include "made a new post:"
      end

      it "renders the article's title" do
        expect(response.body).to include CGI.escapeHTML(article.title)
      end

      it "renders the author's name" do
        expect(response.body).to include CGI.escapeHTML(article.user.name)
      end
    end
  end
end
