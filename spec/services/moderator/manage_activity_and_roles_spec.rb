require "rails_helper"

RSpec.describe Moderator::ManageActivityAndRoles, type: :service do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

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
    context "when user is in limited role" do
      before { user.add_role(:limited) }

      it "adding #{status} also removes the limited role" do
        expect(user.roles.pluck(:name)).to include("limited") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).not_to include("limited") # confirm assumptions
      end
    end

    context "when user is in suspended role" do
      before { user.add_role(:suspended) }

      it "adding #{status} also removes the suspended role" do
        expect(user.roles.pluck(:name)).to include("suspended") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).not_to include("suspended") # confirm assumptions
      end
    end

    context "when user is in warned role" do
      before { user.add_role(:warned) }

      it "adding #{status} also removes the warned role" do
        expect(user.roles.pluck(:name)).to include("warned") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).not_to include("warned") # confirm assumptions
      end
    end

    context "when user is in spam role" do
      before { user.add_role(:spam) }

      it "adding #{status} also removes the spam role" do
        expect(user.roles.pluck(:name)).to include("spam") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).not_to include("spam") # confirm assumptions
      end
    end

    context "when user is in comment_suspended role" do
      before { user.add_role(:comment_suspended) }

      it "adding #{status} also removes the comment_suspended role" do
        expect(user.roles.pluck(:name)).to include("comment_suspended") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).not_to include("comment_suspended") # confirm assumptions
      end
    end
  end

  shared_examples_for "negative role" do |status|
    context "when user is in trusted role" do
      before { user.add_role(:trusted) }

      it "adding #{status} removes the trusted role" do
        expect(user.roles.pluck(:name)).to include("trusted") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).not_to include("trusted") # confirm assumptions
      end
    end

    context "when user is in tag_moderator role" do
      before { user.add_role(:tag_moderator) }

      it "adding #{status} removes the tag_moderator role" do
        expect(user.roles.pluck(:name)).to include("tag_moderator") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).not_to include("tag_moderator") # confirm assumptions
      end
    end

    context "when user is in admin role" do
      before { user.add_role(:admin) }

      it "adding #{status} ignores the admin role" do
        expect(user.roles.pluck(:name)).to include("admin") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).to include("admin") # confirm assumptions
      end
    end

    context "when user is in super_moderator role" do
      before { user.add_role(:super_moderator) }

      it "adding #{status} ignores the super_moderator role" do
        expect(user.roles.pluck(:name)).to include("super_moderator") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).to include("super_moderator") # confirm assumptions
      end
    end

    context "when user is in tech_admin role" do
      before { user.add_role(:tech_admin) }

      it "adding #{status} ignores the tech_admin role" do
        expect(user.roles.pluck(:name)).to include("tech_admin") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).to include("tech_admin") # confirm assumptions
      end
    end

    context "when user is in limited role" do
      before { user.add_role(:limited) }

      it "adding #{status} ignores the limited role" do
        expect(user.roles.pluck(:name)).to include("limited") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).to include("limited") # confirm assumptions
      end
    end

    context "when user is in warned role" do
      before { user.add_role(:warned) }

      it "adding #{status} ignores the warned role" do
        expect(user.roles.pluck(:name)).to include("warned") # confirm assumptions
        manage_roles_for user, user_status: status
        expect(user.roles.pluck(:name)).to include("warned") # confirm assumptions
      end
    end
  end

  it_behaves_like "elevated role", "Admin"
  it_behaves_like "elevated role", "Super Moderator"
  it_behaves_like "elevated role", "Resource Admin: Tag"
  it_behaves_like "elevated role", "Super Admin"
  it_behaves_like "elevated role", "Trusted"
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

  it "user in 'Good standing' has no negative or elevated roles" do
    user.add_role(:comment_suspended)
    user.add_role(:warned)
    user.add_role(:trusted)
    manage_roles_for(user, user_status: "Good standing")
    expect(user.suspended?).to be false
    expect(user.roles.count).to eq(0)
    expect(user.has_trusted_role?).to be false
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
    let(:spam_user) { create(:user) }
    let(:spam_article) { create(:article, user: spam_user) }
    let!(:report) do
      create(:feedback_message, category: "spam", status: "Open", reported_url: URL.url(spam_article.path))
    end

    it "calls ResolveSpamReports" do
      allow(Users::ResolveSpamReports).to receive(:call)
      sidekiq_perform_enqueued_jobs do
        manage_roles_for(spam_user, user_status: "Spam")
      end
      expect(Users::ResolveSpamReports).to have_received(:call).with(spam_user)
    end

    it "actually removes the report" do
      sidekiq_perform_enqueued_jobs do
        manage_roles_for(spam_user, user_status: "Spam")
      end
      expect(report.reload.status).to eq("Resolved")
    end
  end

  describe "confirms flag reactions when adding the spam role" do
    let(:spam_user) { create(:user) }
    let(:spam_article) { create(:article, user: spam_user) }
    let!(:flag) do
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

    it "calls ConfirmFlagReactionsWorker" do
      allow(Users::ConfirmFlagReactions).to receive(:call)
      sidekiq_perform_enqueued_jobs do
        manage_roles_for(spam_user, user_status: "Spam")
      end
      expect(Users::ConfirmFlagReactions).to have_received(:call).with(spam_user)
    end

    it "actually confirms the flag" do
      sidekiq_perform_enqueued_jobs do
        manage_roles_for(spam_user, user_status: "Spam")
      end
      expect(flag.reload.status).to eq("confirmed")
    end
  end

  describe "removes notifications when adding the spam role" do
    let(:nice_article) { create(:article, user: user) }
    let(:spam_user) { create(:user) }
    let(:spam_article) { create(:article, user: spam_user) }
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

    it "raises exception when trying to upgrade user to super admin" do
      expect do
        manage_roles_for(user, user_status: "Super Admin")
      end.to raise_error(StandardError)
    end

    it "raises exception when trying to upgrade user to admin" do
      expect do
        manage_roles_for(user, user_status: "Admin")
      end.to raise_error(StandardError)
    end

    it "raises exception when trying to upgrade user to single resource admin" do
      expect do
        manage_roles_for(user, user_status: "Resource Admin: Article")
      end.to raise_error(StandardError)
    end

    it "raises exception when trying to upgrade user to super moderator" do
      expect do
        manage_roles_for(user, user_status: "Super Moderator")
      end.to raise_error(StandardError)
    end
  end
end
