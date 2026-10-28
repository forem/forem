require "rails_helper"

RSpec.describe Moderator::ManageActivityAndRoles, type: :service do
  let(:user) { create(:user, profile_image: nil) }
  let(:admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }

  def manage_roles_for(user, user_status:, note: "Test note", acting_as: admin)
    described_class.handle_user_roles(
      admin: acting_as,
      user: user,
      user_params: {
        note_for_current_role: note,
        user_status: user_status
      },
    )
  end

  shared_examples_for "elevated role" do |status|
    it "adding #{status} also removes negative roles", :aggregate_failures do
      negative_roles = %w[limited suspended warned spam comment_suspended]
      negative_roles.each { |role| user.add_role(role.to_sym) }
      expect(user.roles.pluck(:name)).to include(*negative_roles)

      manage_roles_for(user, user_status: status)

      expect(user.roles.pluck(:name)).not_to include(*negative_roles)
    end
  end

  shared_examples_for "negative role" do |status|
    it "adding #{status} removes moderator roles and ignores admin, limited, and warned roles", :aggregate_failures do
      removed_roles = %w[trusted tag_moderator community_leader_level_1]
      ignored_roles = %w[admin super_moderator tech_admin limited warned]
      (removed_roles + ignored_roles).each { |role| user.add_role(role.to_sym) }
      expect(user.roles.pluck(:name)).to include(*removed_roles, *ignored_roles)

      manage_roles_for(user, user_status: status)

      role_names = user.roles.pluck(:name)
      expect(role_names).not_to include(*removed_roles)
      expect(role_names).to include(*ignored_roles)
    end
  end

  it_behaves_like "elevated role", "Admin"
  it_behaves_like "elevated role", "Super Moderator"
  it_behaves_like "elevated role", "Resource Admin: Tag"
  it_behaves_like "elevated role", "Super Admin"
  it_behaves_like "elevated role", "Trusted"
  it_behaves_like "elevated role", "Community Leader Level 1"
  it_behaves_like "elevated role", "Community Leader Level 2"
  it_behaves_like "elevated role", "Good standing"
  it_behaves_like "elevated role", "Tech Admin"

  it_behaves_like "negative role", "Suspended"
  it_behaves_like "negative role", "Spam"
  it_behaves_like "negative role", "Limited"
  it_behaves_like "negative role", "Warned"

  context "when user is in suspended role" do
    it "adding warned removes the suspended role" do
      user.add_role(:suspended)
      expect(user.roles.pluck(:name)).to include("suspended") # confirm assumptions
      manage_roles_for user, user_status: "Warned"
      expect(user.roles.pluck(:name)).not_to include("suspended") # confirm assumptions
    end

    it "adding warned removes the spam role" do
      user.add_role(:spam)
      expect(user.roles.pluck(:name)).to include("spam")
      manage_roles_for user, user_status: "Warned"
      expect(user.roles.pluck(:name)).not_to include("spam")
    end
  end

  it "updates user status to limited" do
    expect(user).not_to be_limited
    manage_roles_for(user, user_status: "Limited")
    expect(user).to be_limited
    manage_roles_for(user, user_status: "Good standing")
    expect(user).not_to be_limited
  end

  it "updates user to base subscriber" do
    expect(user).not_to be_base_subscriber
    manage_roles_for(user, user_status: "Base Subscriber")
    expect(user).to be_base_subscriber
  end

  it "updates user to super admin" do
    expect(user).not_to be_super_admin
    expect(user.has_trusted_role?).to be false
    manage_roles_for(user, user_status: "Super Admin")
    expect(user).to be_super_admin
    expect(user.has_trusted_role?).to be true
  end

  it "updates user to admin" do
    expect(user).not_to be_admin
    expect(user.has_trusted_role?).to be false
    manage_roles_for(user, user_status: "Admin")
    expect(user).to be_admin
    expect(user.has_trusted_role?).to be true
  end

  it "updates user to tech admin" do
    expect(user).not_to be_tech_admin
    expect(user.single_resource_admin_for?(DataUpdateScript)).to be false
    manage_roles_for(user, user_status: "Tech Admin")
    expect(user).to be_tech_admin
    expect(user.single_resource_admin_for?(DataUpdateScript)).to be true
  end

  it "updates user to single resource admin" do
    expect(user.single_resource_admin_for?(Article)).to be false
    manage_roles_for(user, user_status: "Resource Admin: Article")
    expect(user.single_resource_admin_for?(Article)).to be true
  end

  it "updates user to community leader level 1 and grants the trusted role" do
    expect(user.community_leader?).to be false
    expect(user.has_trusted_role?).to be false
    manage_roles_for(user, user_status: "Community Leader Level 1")
    expect(user.community_leader_level_1?).to be true
    expect(user.has_trusted_role?).to be true
  end

  it "swaps community leader level when promoting from 1 to 2" do
    manage_roles_for(user, user_status: "Community Leader Level 1")
    manage_roles_for(user, user_status: "Community Leader Level 2")
    expect(user.community_leader_level_2?).to be true
    expect(user.community_leader_level_1?).to be false
  end

  it "allows a regular admin (not super admin) to assign a community leader role" do
    regular_admin = create(:user, :admin, :without_profile, profile_image: nil)
    manage_roles_for(user, user_status: "Community Leader Level 1", acting_as: regular_admin)
    expect(user.community_leader_level_1?).to be true
  end

  it "user in 'Good standing' has no negative or elevated roles" do
    user.add_role(:comment_suspended)
    user.add_role(:warned)
    user.add_role(:trusted)
    user.add_role(:community_leader_level_1)
    manage_roles_for(user, user_status: "Good standing")
    expect(user.suspended?).to be false
    expect(user.roles.count).to eq(0)
    expect(user.has_trusted_role?).to be false
    expect(user.community_leader?).to be false
  end

  describe "Rack::Attack cache invalidation optimization" do
    before do
      cache_db = ActiveSupport::Cache.lookup_store(:redis_cache_store)
      allow(Rails).to receive(:cache) { cache_db }

      allow(Rails.cache).to receive(:delete)
      allow(Rails.cache).to receive(:delete)
        .with(Rack::Attack::ADMIN_API_CACHE_KEY)
    end

    it "clears Rack::Attack cache if assigned admin role to user" do
      described_class.handle_user_roles(
        admin: admin,
        user: user,
        user_params: { note_for_current_role: "Upgrading to tech admin", user_status: "Super Admin" },
      )

      expect(Rails.cache).to have_received(:delete)
        .with(Rack::Attack::ADMIN_API_CACHE_KEY)
    end

    it "doesn't Rack::Attack cache if assigned non-admin role to user" do
      user.add_role(:comment_suspended)
      described_class.handle_user_roles(
        admin: admin,
        user: user,
        user_params: { note_for_current_role: "Upgrading to trusted user", user_status: "Good standing" },
      )

      expect(Rails.cache).not_to have_received(:delete)
        .with(Rack::Attack::ADMIN_API_CACHE_KEY)
    end
  end

  describe "removes reports when adding the spam role" do
    let(:spam_user) { create(:user, profile_image: nil) }
    let(:spam_article) { create(:article, user: spam_user, with_tags: false) }
    let!(:report) do
      create(:feedback_message, category: "spam", status: "Open", reported_url: URL.url(spam_article.path))
    end

    it "calls ResolveSpamReports and resolves the report", :aggregate_failures do
      allow(Users::ResolveSpamReports).to receive(:call).and_call_original
      sidekiq_perform_enqueued_jobs do
        manage_roles_for(spam_user, user_status: "Spam")
      end
      expect(Users::ResolveSpamReports).to have_received(:call).with(spam_user)
      expect(report.reload.status).to eq("Resolved")
    end
  end

  describe "confirms flag reactions when adding the spam role" do
    let(:spam_user) { create(:user, profile_image: nil) }
    let(:spam_article) { create(:article, user: spam_user, with_tags: false) }
    let(:flag) do
      create(:reaction, category: "vomit", status: "valid", reactable: spam_article, user: admin)
    end

    it "schedules ConfirmFlagReactionsWorker" do
      sidekiq_assert_enqueued_with(
        job: Users::ConfirmFlagReactionsWorker,
        args: [spam_user.id],
      ) do
        manage_roles_for(spam_user, user_status: "Spam")
      end
    end

    it "calls ConfirmFlagReactions and confirms the flag", :aggregate_failures do
      flag
      allow(Users::ConfirmFlagReactions).to receive(:call).and_call_original
      sidekiq_perform_enqueued_jobs do
        manage_roles_for(spam_user, user_status: "Spam")
      end
      expect(Users::ConfirmFlagReactions).to have_received(:call).with(spam_user)
      expect(flag.reload.status).to eq("confirmed")
    end
  end

  describe "busts user profile header cache when adding the spam role" do
    it "touches profile" do
      profile = instance_double(Profile)
      allow(user).to receive(:profile).and_return(profile)
      allow(profile).to receive(:touch)
      manage_roles_for(user, user_status: "Spam")
      expect(profile).to have_received(:touch)
    end
  end

  describe "removes notifications when adding the spam role" do
    let(:nice_article) { create(:article, user: user, with_tags: false) }
    let(:spam_user) { create(:user, profile_image: nil) }
    let(:spam_article) { create(:article, user: spam_user, with_tags: false) }
    let(:spam_follow) { create(:follow, follower: spam_user, followable: user) }
    let(:spam_comment) { create(:comment, user: spam_user, commentable: nice_article) }

    before do
      create(:notification, notifiable: spam_comment, user: user)
      create(:notification, notifiable: spam_article, action: "Published", user: user)
      create(:notification, notifiable: spam_follow, user: user)
    end

    it "removes notifications related to the spammer" do
      expect(Notification.count).to eq(3)
      expect do
        sidekiq_perform_enqueued_jobs do
          manage_roles_for(spam_user, user_status: "Spam")
        end
      end.to change(Notification, :count).by(-3)
    end
  end

  context "when not super admin" do
    before do
      admin.remove_role(:super_admin)
      admin.add_role(:admin)
    end

    it "raises exception when trying to upgrade user to restricted roles", :aggregate_failures do
      ["Super Admin", "Admin", "Resource Admin: Article", "Super Moderator", "Community Leader Level 2"].each do |role|
        expect do
          manage_roles_for(user, user_status: role)
        end.to raise_error(StandardError)
      end
    end

    it "raises exception when trying to downgrade a community leader level 2 user to level 1" do
      user.add_role(:community_leader_level_2)

      expect do
        manage_roles_for(user, user_status: "Community Leader Level 1")
      end.to raise_error(StandardError)

      expect(user.reload.community_leader_level_2?).to be(true)
    end
  end
end
