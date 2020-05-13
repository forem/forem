require "rails_helper"

RSpec.describe "Internal::Users", type: :request do
  let!(:user) { create(:user, twitter_username: nil, old_username: "username") }
  let!(:user2) { create(:user, twitter_username: "Twitter") }
  let(:user3) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user2) }
  let(:badge) { create(:badge, title: "one-year-club") }
  let(:ghost) { create(:user, username: "ghost", github_username: "Ghost") }
  let(:organization) { create(:organization) }

  before do
    sign_in super_admin
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
    sidekiq_perform_enqueued_jobs do
      Mention.create_all(comment2)
    end
  end

  def offender_activity_on_other_content
    # offender reacts to user2 article
    create(:reaction, reactable: article2, reactable_type: "Article", user: user)
    # offender comments on user2 article
    comment = create(:comment, commentable_type: "Article", commentable: article2, user: user)
    # user3 reacts to offender comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
  end

  def full_profile
    BadgeAchievement.create(
      user_id: user2.id,
      badge_id: badge.id,
      rewarding_context_message_markdown: "message",
    )
    ChatChannel.create_with_users(users: [user2, user3], channel_type: "direct")
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
  end

  def call_ghost
    ghost
    post "/internal/users/#{user.id}/full_delete", params: { user: { ghostify: "true" } }
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
      expect(Follow.followable_user(user.id).count).to eq(1)
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

  context "when managing activity and roles" do
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

  context "when deleting user and converting content to ghost" do
    it "raises a 'record not found' error after deletion" do
      call_ghost
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "reassigns comment and article content to ghost account" do
      create(:article, user: user)
      call_ghost
      articles = ghost.articles
      expect(articles.count).to eq(2)
      expect(ghost.comments.count).to eq(1)
      expect(ghost.comments.last.path).to include("ghost")
      expect(articles.last.path).to include("ghost")
      expect(articles.last.elasticsearch_doc.dig("_source", "path")).to include("ghost")
    end
  end

  context "when deleting user" do
    def create_mention
      comment = create(
        :comment,
        body_markdown: "Hello @#{user.username}, you are cool.",
        user_id: user2.id,
        commentable: article2,
      )
      sidekiq_perform_enqueued_jobs do
        Mention.create_all(comment)
      end
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
    end

    it "raises a 'record not found' error after deletion" do
      sidekiq_perform_enqueued_jobs do
        post "/internal/users/#{user.id}/full_delete", params: { user: { ghostify: "false" } }
      end
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "expect flash message" do
      post "/internal/users/#{user.id}/full_delete", params: { user: { ghostify: "false" } }
      expect(request.flash["success"]).to include("fully deleted")
    end
  end

  context "when handling credits" do
    before do
      create(:organization_membership, user: super_admin, organization: organization, type_of_user: "admin")
    end

    it "adds the proper amount of credits for organizations" do
      put "/internal/users/#{super_admin.id}", params: {
        user: {
          add_org_credits: 5,
          organization_id: organization.id
        }
      }
      expect(organization.reload.credits_count).to eq 5
      expect(organization.reload.unspent_credits_count).to eq 5
    end

    it "removes the proper amount of credits for organizations" do
      Credit.add_to_org(organization, 10)
      put "/internal/users/#{super_admin.id}", params: {
        user: {
          remove_org_credits: 5,
          organization_id: organization.id
        }
      }
      expect(organization.reload.credits_count).to eq 5
      expect(organization.reload.unspent_credits_count).to eq 5
    end

    it "add the proper amount of credits to a user" do
      put "/internal/users/#{super_admin.id}", params: {
        user: {
          add_credits: 5
        }
      }
      expect(super_admin.reload.credits_count).to eq 5
      expect(super_admin.reload.unspent_credits_count).to eq 5
    end

    it "removes the proper amount of credits from a user" do
      Credit.add_to(super_admin, 10)
      put "/internal/users/#{super_admin.id}", params: {
        user: {
          remove_credits: 5
        }
      }
      expect(super_admin.reload.credits_count).to eq 5
      expect(super_admin.reload.unspent_credits_count).to eq 5
    end
  end
end
