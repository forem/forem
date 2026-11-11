require "rails_helper"

RSpec.describe "Admin::Users" do
  let(:user) { create(:user, twitter_username: nil, old_username: "username") }
  let(:user2) { create(:user, twitter_username: "Twitter") }
  let(:user3) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user2) }
  let(:badge) { create(:badge, title: "one-year-club") }
  let(:organization) { create(:organization) }
  let(:rewarder) { create(:user) }

  before do
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    sign_in super_admin
  end

  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    if name == :article
      options[:with_tags] = false unless options.key?(:tag_list) || options.key?(:tags) || options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    end
    super
  end

  def create_list(name, amount, *traits, **options)
    return Array.new(amount) { create(name, *traits, **options) } if %i[user article].include?(name)

    super
  end

  def dependents_for_offending_user_article
    # create user2 comment on offending user article
    comment = create(:comment, commentable_type: "Article", commentable: article, user: user2)
    # create user3 reaction to user2 comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
    # create user3 comment response to user2 comment
    comment2 = create(:comment, commentable_type: "Article", commentable: article, user: user3, ancestry: comment.id,
                                body_markdown: "Hello @#{user2.username}, you are cool.")
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
    user.create_profile!
    user2.create_profile!
    BadgeAchievement.create(
      user_id: user2.id,
      badge_id: badge.id,
      rewarding_context_message_markdown: "message",
    )
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

  context "when merging users" do
    it "merges content, relationships, identities, profile info, and social usernames, and deletes duplicate user",
       :aggregate_failures do
      omniauth_mock_twitter_payload
      omniauth_mock_github_payload
      create(:identity, user: user, provider: "twitter")
      deleted_user_identity = create(:identity, user: user2)
      dependents_for_offending_user_article
      offender_activity_on_other_content
      full_profile

      expected_articles_count = user.articles.count + user2.articles.count
      expected_comments_count = user.comments.count + user2.comments.count
      expected_reactions_count = user.reactions.count + user2.reactions.count
      expected_follows_count = user.follows.count + user2.follows.count
      expected_mentions_count = user.mentions.count + user2.mentions.count

      sidekiq_assert_enqueued_with(job: Users::DeleteWorker, args: [user2.id, true, "merge"]) do
        post merge_admin_user_path(user.id), params: { user: { merge_user_id: user2.id } }
      end

      expect(user.comments.count).to eq(expected_comments_count)
      expect(user.articles.count).to eq(expected_articles_count)
      expect(user.reactions.count).to eq(expected_reactions_count)
      expect(user.follows.count).to eq(expected_follows_count)
      expect(Follow.followable_user(user.id).count).to eq(1)
      expect(user.mentions.count).to eq(expected_mentions_count)
      expect(user.github_repos.any?).to be true
      expect(user.badge_achievements.any?).to be true
      expect(user.identities.count).to eq 2
      expect(user.identity_ids).to include deleted_user_identity.id
      expect(user.reload.twitter_username).to eq("Twitter")

      sidekiq_perform_enqueued_jobs(only: Users::DeleteWorker)

      expect { User.find(user2.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  context "when managing activity and roles" do
    it "adds comment suspend and limited roles and records notes", :aggregate_failures do
      patch user_status_admin_user_path(user.id), params: {
        user: { user_status: "Comment Suspended", note_for_current_role: "comment suspend this user" }
      }
      expect(user.reload.roles.first.name).to eq("comment_suspended")
      expect(Note.last.content).to eq("comment suspend this user")

      patch user_status_admin_user_path(user.id), params: {
        user: { user_status: "Limited", note_for_current_role: "limited role added" }
      }
      expect(user.reload.roles.pluck(:name)).to include("limited")
      expect(Note.last.content).to eq("limited role added")
    end

    it "allows admins to assign and remove community leader level 1 but not level 2", :aggregate_failures do
      sign_in create(:user, :admin)

      patch user_status_admin_user_path(user.id), params: {
        user: { user_status: "Community Leader Level 1", note_for_current_role: "assigning community leader" }
      }
      expect(user.reload.community_leader_level_1?).to be(true)

      patch user_status_admin_user_path(user.id), params: {
        user: { user_status: "Community Leader Level 2", note_for_current_role: "assigning level 2" }
      }
      expect(user.reload.community_leader_level_2?).to be(false)
      expect(request.flash["danger"]).to be_present

      role = user.roles.find_by!(name: "community_leader_level_1")
      delete admin_user_path(user.id), params: { user_id: user.id, role_id: role.id }

      expect(user.reload.community_leader_level_1?).to be(false)
      expect(request.flash["success"]).to include("Community Leader Level 1")
    end

    it "selects new role for user" do
      user.add_role(:trusted)
      user.reload

      params = { user: { user_status: "Comment Suspended", note_for_current_role: "comment suspend this user" } }
      patch user_status_admin_user_path(user.id), params: params

      expect(user.roles.count).to eq(1)
      expect(user.roles.last.name).to eq("comment_suspended")
    end

    it "selects super admin role when user was suspended" do
      user.add_role(:suspended)
      user.reload

      params = { user: { user_status: "Super Admin", note_for_current_role: "they deserve it for some reason" } }
      patch user_status_admin_user_path(user.id), params: params

      expect(user.super_admin?).to be(true)
    end

    it "does not allow non-super-admin to doll out admin" do
      super_admin.remove_role(:super_admin)
      super_admin.add_role(:super_admin)
      super_admin.reload

      params = { user: { user_status: "Super Admin", note_for_current_role: "they deserve it for some reason" } }
      patch user_status_admin_user_path(user.id), params: params

      expect(user.super_admin?).not_to be false
    end

    it "creates a general note on the user" do
      put admin_user_path(user.id), params: { user: { new_note: "general note about whatever" } }
      expect(Note.last.content).to eq("general note about whatever")
    end

    it "updates profile fields and records a note", :aggregate_failures do
      user.create_profile!(
        summary: "Old summary",
        location: "Old location",
        website_url: "https://old.example.com",
      )

      patch update_profile_admin_user_path(user.id), params: {
        user: { name: "New Name", username: "newuserhandle" },
        profile: { summary: "New summary", location: "New location", website_url: "https://new.example.com" }
      }

      user.reload

      expect(user.name).to eq("New Name")
      expect(user.username).to eq("newuserhandle")
      expect(user.profile.summary).to eq("New summary")
      expect(user.profile.location).to eq("New location")
      expect(user.profile.website_url).to eq("https://new.example.com")
      expect(Note.last.reason).to eq("admin_profile_update")
      expect(Note.last.content).to include("Admin #{super_admin.username} updated profile fields")
      expect(Note.last.content).to include("name:")
      expect(Note.last.content).to include("username:")
      expect(Note.last.content).to include("summary:")
      expect(Note.last.content).to include("location:")
      expect(Note.last.content).to include("website_url:")
    end

    it "remove credits from account" do
      create_list(:credit, 5, user: user)
      put admin_user_path(user.id), params: { user: { remove_credits: "3" } }
      expect(user.credits.size).to eq(2)
    end

    it "updates a user's password when confirmation matches and fails on mismatch", :aggregate_failures do
      patch update_password_admin_user_path(user.id), params: {
        user: { password: "new-password-123", password_confirmation: "mismatch-456" }
      }

      expect(response).to redirect_to(admin_user_path(user.id, tab: :security))
      expect(flash[:error]).to be_present
      expect(user.reload.valid_password?("new-password-123")).to be(false)

      patch update_password_admin_user_path(user.id), params: {
        user: { password: "new-password-123", password_confirmation: "new-password-123" }
      }

      expect(response).to redirect_to(admin_user_path(user.id, tab: :security))
      expect(user.reload.valid_password?("new-password-123")).to be(true)
      expect(Note.last.reason).to eq("admin_password_update")
    end

    it "sends an admin-triggered password reset email and falls back to username if admin name is blank",
       :aggregate_failures do
      expect do
        perform_enqueued_jobs do
          post send_password_reset_admin_user_path(user.id)
        end
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(response).to redirect_to(admin_user_path(user.id, tab: :security))
      expect(Note.last.reason).to eq("admin_password_reset")

      email = ActionMailer::Base.deliveries.last
      expect(email.body.encoded).to include(CGI.escapeHTML(super_admin.name))
      expect(email.body.encoded).to include("help you regain access")

      super_admin.update_column(:name, nil)

      expect do
        perform_enqueued_jobs do
          post send_password_reset_admin_user_path(user.id)
        end
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(ActionMailer::Base.deliveries.last.body.encoded).to include(super_admin.username)
    end

    it "removes non-admin roles from non-super_admin users", :aggregate_failures do
      role = user.add_role(:trusted)

      expect do
        delete admin_user_path(user.id), params: { user_id: user.id, role_id: role.id }
      end.to change(user.roles, :count).by(-1)

      expect(user.has_trusted_role?).to be false
      expect(request.flash["success"]).to include("successfully removed from the user!")
    end

    it "removes the correct resource_admin_role from non-super_admin users", :aggregate_failures do
      role = user.add_role(:single_resource_admin, Comment)
      user.add_role(:single_resource_admin, Broadcast)

      expect do
        delete admin_user_path(user.id),
               params: { user_id: user.id, role_id: role.id, resource_type: Comment }
      end.to change(user.roles, :count).by(-1)

      expect(user.single_resource_admin_for?(Comment)).to be false
      expect(user.single_resource_admin_for?(Broadcast)).to be true
      expect(request.flash["success"]).to include("successfully removed from the user!")
    end

    it "removes only the targeted tag mod role", :aggregate_failures do
      tag = create(:tag)
      tag2 = create(:tag)
      role = user.add_role(:tag_moderator, tag)
      user.add_role(:tag_moderator, tag2)

      expect do
        delete admin_user_path(user.id),
               params: { user_id: user.id, role_id: role.id, resource_type: "Tag", resource_id: tag.id }
      end.to change(user.roles, :count).by(-1)

      user.reload
      expect(user.tag_moderator?(tag: tag)).to be false
      expect(user.tag_moderator?(tag: tag2)).to be true
    end
  end

  context "when adding tag moderator role" do
    let(:tag) { create(:tag, name: "ruby") }

    it "adds role for an existing tag and displays an error when not found", :aggregate_failures do
      post add_tag_mod_role_admin_user_path(user.id), params: { user: { tag_name: tag.name } }
      expect(user.reload.tag_moderator?(tag: tag)).to be true
      expect(response).to redirect_to(admin_user_path(user.id))

      tag_name = "su#{tag.name}per"
      post add_tag_mod_role_admin_user_path(user.id), params: { user: { tag_name: tag_name } }
      expect(flash[:error]).to include("Error: Tag \"#{tag_name}\" was not found")
      expect(response).to redirect_to(admin_user_path(user.id))
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

    it "deletes the user's content and purges caches once the background jobs run", :aggregate_failures do
      user.create_profile!
      dependents_for_offending_user_article
      offender_activity_on_other_content
      create_mutual_follows
      create_mention
      create(:badge_achievement, rewarder: rewarder, rewarding_context_message: "yay", user: user)

      allow(EdgeCache::PurgeByKey).to receive(:call)
      offender_comment = user.comments.sole
      profile_keys = user.profile_cache_keys

      # the outer block runs the jobs the deletion job enqueues
      sidekiq_perform_enqueued_jobs do
        sidekiq_perform_enqueued_jobs { post full_delete_admin_user_path(user.id) }
      end

      expect(User.exists?(user.id)).to be(false)
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
      expect(Article.exists?(article.id)).to be(false)
      expect(Comment.where(commentable: article)).to be_empty
      expect(Comment.exists?(offender_comment.id)).to be(false)
      expect(Reaction.where(user_id: user.id)).to be_empty
      expect(Follow.followable_user(user.id)).to be_empty
      expect(Article.exists?(article2.id)).to be(true)
      expect(GDPRDeleteRequest.where(user_id: user.id)).to exist
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(profile_keys, fallback_paths: anything).at_least(:once)
      expect(EdgeCache::PurgeByKey).to have_received(:call)
        .with(array_including(offender_comment.record_key), fallback_paths: anything)
    end

    it "enqueues the deletion and sets a background deletion flash message without deleting inline",
       :aggregate_failures do
      sidekiq_assert_enqueued_with(job: Users::DeleteWorker, args: [user.id, true]) do
        post full_delete_admin_user_path(user.id)
      end
      expect(User.exists?(user.id)).to be(true)
      expect(response).to redirect_to(admin_users_path)
      expect(request.flash["success"]).to include("is being deleted")
      expect(request.flash["success"]).to include("removed in the background")
      expect(request.flash["success"]).not_to include("fully deleted")
    end

    it "allows admins to delete users below the published activity threshold and forbids deleting admins",
       :aggregate_failures do
      admin = create(:user, :admin)
      sign_in admin

      expect do
        post full_delete_admin_user_path(super_admin.id)
      end.to raise_error(Pundit::NotAuthorizedError)

      expect do
        post full_delete_admin_user_path(admin.id)
      end.to raise_error(Pundit::NotAuthorizedError)

      get admin_user_path(user.id)
      expect(response.body).to include(full_delete_admin_user_path(user))

      sidekiq_assert_enqueued_jobs(1, only: Users::DeleteWorker) do
        post full_delete_admin_user_path(user.id)
      end

      expect(response).to redirect_to(admin_users_path)
    end

    it "restricts deleting users at or above the published activity threshold to super admins", :aggregate_failures do
      stub_const("UserPolicy::ADMIN_DELETE_PUBLISHED_ACTIVITY_LIMIT", 1)
      article
      admin = create(:user, :admin)
      sign_in admin

      get admin_user_path(user.id)
      expect(response.body).to include(
        I18n.t("views.admin.users.delete.activity_threshold_notice",
               count: UserPolicy::ADMIN_DELETE_PUBLISHED_ACTIVITY_LIMIT),
      )
      expect(response.body).not_to include(full_delete_admin_user_path(user))

      expect do
        post full_delete_admin_user_path(user.id)
      end.to raise_error(Pundit::NotAuthorizedError)

      sign_in super_admin

      get admin_user_path(user.id)
      expect(response.body).to include(
        I18n.t("views.admin.users.delete.activity_threshold_notice",
               count: UserPolicy::ADMIN_DELETE_PUBLISHED_ACTIVITY_LIMIT),
      )
      expect(response.body).to include(full_delete_admin_user_path(user))

      sidekiq_assert_enqueued_jobs(1, only: Users::DeleteWorker) do
        post full_delete_admin_user_path(user.id)
      end

      expect(response).to redirect_to(admin_users_path)
    end
  end

  context "when handling credits" do
    it "adds and removes the proper amount of credits for organizations", :aggregate_failures do
      create(:organization_membership, user: super_admin, organization: organization, type_of_user: "admin")

      put admin_user_path(super_admin.id), params: {
        user: { add_org_credits: 10, organization_id: organization.id }
      }
      expect(organization.reload.credits_count).to eq 10
      expect(organization.unspent_credits_count).to eq 10

      put admin_user_path(super_admin.id), params: {
        user: { remove_org_credits: 5, organization_id: organization.id }
      }
      expect(organization.reload.credits_count).to eq 5
      expect(organization.unspent_credits_count).to eq 5
    end

    it "adds and removes the proper amount of credits for a user", :aggregate_failures do
      put admin_user_path(super_admin.id), params: { user: { add_credits: 10 } }
      expect(super_admin.reload.credits_count).to eq 10
      expect(super_admin.unspent_credits_count).to eq 10

      put admin_user_path(super_admin.id), params: { user: { remove_credits: 5 } }
      expect(super_admin.reload.credits_count).to eq 5
      expect(super_admin.unspent_credits_count).to eq 5
    end
  end
  # rubocop:enable RSpec/IndexedLet
end
