require "rails_helper"

RSpec.describe "Internal::Users", type: :request do
  let!(:user) { create(:user, twitter_username: nil) }
  let!(:user2) { create(:user, twitter_username: "Twitter") }
  let(:user3) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user2) }
  let(:badge) { create(:badge, title: "one-year-club") }

  before do
    sign_in super_admin
    Delayed::Worker.new(quiet: true).work_off
    dependents_for_offending_user_article
    offender_activity_on_other_content
  end

  def dependents_for_offending_user_article
    # create user2 comment on offending user article
    comment = create(:comment, commentable_type: "Article", commentable: article, user: user2)
    # create user3 reaction to user2 comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
    # create user3 comment response to user2 comment
    comment2 = create(:comment, commentable_type: "Article", commentable: article, user: user3, ancestry: comment.id, body_markdown: "Hello @#{user2.username}, you are cool.")
    # create user2 reaction to user3 comment response
    create(:reaction, reactable: comment2, reactable_type: "Comment", user: user2)
    # create user3 reaction to offending article
    create(:reaction, reactable: article, reactable_type: "Article", user: user3, category: "like")
    Mention.create_all_without_delay(comment2)
    Delayed::Worker.new(quiet: true).work_off
  end

  def offender_activity_on_other_content
    # offender reacts to user2 article
    create(:reaction, reactable: article2, reactable_type: "Article", user: user)
    # offender comments on user2 article
    comment = create(:comment, commentable_type: "Article", commentable: article2, user: user)
    # user3 reacts to offender comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
    Delayed::Worker.new(quiet: true).work_off
  end

  def full_profile
    BadgeAchievement.create(
      user_id: user2.id,
      badge_id: badge.id,
      rewarding_context_message_markdown: "message",
    )
    ChatChannel.create_with_users([user2, user3], "direct")
    user2.follow(user3)
    user.follow(super_admin)
    user3.follow(user2)
    params = {
      name: Faker::Book.title,
      user_id: user2.id,
      github_id_code: rand(1000),
      url: Faker::Internet.url
    }
    GithubRepo.create(params)
    Delayed::Worker.new(quiet: true).work_off
  end

  context "when merging users" do
    before do
      full_profile
    end

    it "deletes duplicate user" do
      post "/internal/users/#{user.id}/merge", params: { user: { merge_user_id: user2.id } }

      expect { User.find(user2.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "merges all content" do
      expected_articles_count = user.articles.count + user2.articles.count
      expected_comments_count = user.comments.count + user2.comments.count
      expected_reactions_count = user.reactions.count + user2.reactions.count

      post "/internal/users/#{user.id}/merge", params: { user: { merge_user_id: user2.id } }

      expect(user.comments.count).to eq(expected_articles_count)
      expect(user.articles.count).to eq(expected_comments_count)
      expect(user.reactions.count).to eq(expected_reactions_count)
    end

    it "merges all relationships" do
      expected_follows_count = user.follows.count + user2.follows.count
      expected_channel_memberships_count = user.chat_channel_memberships.count + user2.chat_channel_memberships.count
      expected_mentions_count = user.mentions.count + user2.mentions.count

      post "/internal/users/#{user.id}/merge", params: { user: { merge_user_id: user2.id } }

      expect(user.follows.count).to eq(expected_follows_count)
      expect(Follow.where(followable_id: user.id, followable_type: "User").count).to eq(1)
      expect(user.chat_channel_memberships.count).to eq(expected_channel_memberships_count)
      expect(user.mentions.count).to eq(expected_mentions_count)
    end

    it "merges misc profile info" do
      post "/internal/users/#{user.id}/merge", params: { user: { merge_user_id: user2.id } }

      expect(user.github_repos.any?).to be true
      expect(user.badge_achievements.any?).to be true
    end

    it "merges social identities and usernames" do
      post "/internal/users/#{user.id}/merge", params: { user: { merge_user_id: user2.id } }

      expect(user.reload.twitter_username).to eq("Twitter")
    end
  end

  context "when managing activty and roles" do
    it "adds comment ban role" do
      patch "/internal/users/#{user.id}/user_status", params: { user: { user_status: "Comment Ban", note_for_current_role: "comment ban this user" } }
      expect(user.roles.first.name).to eq("comment_banned")
      expect(Note.first.content).to eq("comment ban this user")
    end

    it "selects new role for user" do
      user.add_role :trusted
      user.reload
      patch "/internal/users/#{user.id}/user_status", params: { user: { user_status: "Comment Ban", note_for_current_role: "comment ban this user" } }
      expect(user.roles.count).to eq(1)
      expect(user.roles.last.name).to eq("comment_banned")
    end

    it "creates a general note on the user" do
      put "/internal/users/#{user.id}", params: { user: { new_note: "general note about whatever" } }
      expect(Note.last.content).to eq("general note about whatever")
    end

    it "remove credits from account" do
      create_list(:credit, 5, user: user)
      put "/internal/users/#{user.id}", params: { user: { remove_credits: "3" } }
      expect(user.credits.size).to eq(2)
    end
  end

  context "when deleting user" do
    def create_mention
      comment = create(
        :comment,
        body_markdown: "Hello @#{user.username}, you are cool.",
        user_id: user2.id,
        commentable_id: article2.id,
      )
      Mention.create_all_without_delay(comment)
    end

    def create_mutual_follows
      user.follow(user3)
      follow = user3.follow(user)
      Notification.send_new_follower_notification_without_delay(follow)
    end

    before do
      create_mutual_follows
      create_mention
      create(:badge_achievement, rewarder_id: 1, rewarding_context_message: "yay", user_id: user.id)
      Delayed::Worker.new(quiet: true).work_off
    end

    it "raises a 'record not found' error after deletion" do
      post "/internal/users/#{user.id}/full_delete"
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "expect flash message" do
      post "/internal/users/#{user.id}/full_delete"
      expect(request.flash.notice).to include("fully deleted")
    end
  end

  context "when banning from mentorship" do
    before do
      user.update(offering_mentorship: true, mentor_description: "I want to be a mentor")
    end

    it "adds banned from mentorship role" do
      patch "/internal/users/#{user.id}/user_status", params: { user: { toggle_mentorship: "1", mentorship_note: "banned" } }
      expect(user.roles.first.name).to eq("banned_from_mentorship")
    end

    it "returns user to good standing if unbanned" do
      put "/internal/users/#{user.id}", params: { user: { good_standing_user: "1" } }
      expect(user.roles.count).to eq(0)
    end
  end

  context "when banishing user" do
    def banish_user
      post "/internal/users/#{user.id}/banish"
      Delayed::Worker.new(quiet: true).work_off
      user.reload
    end

    it "reassigns username and removes profile info" do
      user.currently_hacking_on = "currently hackin on !!!!!!!!!!!!"
      user.save
      banish_user
      expect(user.currently_hacking_on).to eq("")
      expect(user.username).to include("spam_")
    end

    it "adds banned role" do
      banish_user
      expect(user.roles.last.name).to eq("banned")
      expect(Note.count).to eq(1)
    end

    it "deletes user content" do
      banish_user
      expect(user.reactions.count).to eq(0)
      expect(user.comments.count).to eq(0)
      expect(user.articles.count).to eq(0)
    end

    it "removes all follow relationships" do
      user.follow(user2)
      banish_user
      expect(user.follows.count).to eq(0)
    end
  end
end
