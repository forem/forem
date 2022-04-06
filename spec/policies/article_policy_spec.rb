require "rails_helper"

# See ./spec/policies/shared_examples/authorization_shared_examples.rb for the various shared examples.
RSpec.describe ArticlePolicy do
  subject(:method_call) { policy.public_send(policy_method) }

  let(:organization) { org_admin&.organizations&.first }

  # The named "folks" with one or more roles
  let(:org_admin) { create(:user, :org_admin) }
  let(:anyone) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:suspended_user) { create(:user, :suspended) }
  let(:admin) { create(:user, :admin) }
  let(:trusted) { create(:user, :trusted) }
  let(:other_users) { create(:user) }
  let(:author) { create(:user) }

  let(:resource) { build(:article, user: author, organization: organization) }
  let(:policy) { described_class.new(user, resource) }

  describe ".scope_users_authorized_to_action" do
    let!(:regular_user) { create(:user) }
    let!(:super_admin_user) { create(:user, :super_admin) }

    before { create(:user, :suspended) }

    context "when limit_post_creation_to_admins is true" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(true) }

      it "omits suspended and regular users" do
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results).to match_array([super_admin_user])
      end
    end

    context "when limit_post_creation_to_admins is false" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false) }

      it "omits only suspended users" do
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results).to match_array([regular_user, super_admin_user])
      end
    end
  end

  describe "#feed?" do
    let(:policy_method) { :feed? }
    let(:user) { build(:user) }

    it { is_expected.to be_truthy }
  end

  %i[create? new?].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "it requires a user in good standing"
      it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: false
      it_behaves_like "permitted roles", to: %i[super_admin admin], limit_post_creation_to_admins?: true
      it_behaves_like "disallowed roles", to: %i[anyone], limit_post_creation_to_admins?: true
    end
  end

  %i[preview? has_existing_articles_or_can_create_new_ones?].each do |method_name|
    describe method_name.to_s do
      let(:policy_method) { method_name }

      it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: false
      it_behaves_like "permitted roles", to: %i[super_admin admin], limit_post_creation_to_admins?: true
      it_behaves_like "disallowed roles", to: %i[anyone], limit_post_creation_to_admins?: true

      context "when user has published articles" do
        before do
          create(:article, published: true, user: user)
        end

        # Below are two scenarios: one with limit_post_creation_to_admins? as true and the other as
        # limit_post_creation_to_admins? as false.  In both cases, when the user has published
        # articles, it doesn't matter if they can create an article or not, the
        # `has_existing_articles_or_can_create_new_ones?` should return true (which is what the
        # "permitted roles" shared spec verifies).
        it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: false
        it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: true
      end

      context "when user has no published articles" do
        before { user.articles.delete_all }

        it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: false
        it_behaves_like "disallowed roles", to: %i[anyone], limit_post_creation_to_admins?: true
      end
    end
  end

  describe "#moderate?" do
    let(:policy_method) { :moderate? }

    it_behaves_like "it requires a user in good standing"
    it_behaves_like "it requires an authenticated user"

    it_behaves_like "permitted roles", to: %i[trusted], limit_post_creation_to_admins?: false

    it_behaves_like "disallowed roles", to: %i[super_admin admin author], limit_post_creation_to_admins?: false
    it_behaves_like "disallowed roles", to: %i[trusted], limit_post_creation_to_admins?: true
  end

  %i[update? edit?].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "it requires a user in good standing"
      it_behaves_like "permitted roles", to: %i[super_admin admin org_admin]
      it_behaves_like "disallowed roles", to: [:other_users]
    end
  end

  describe "#stats?" do
    let(:policy_method) { :stats? }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "permitted roles", to: %i[super_admin org_admin suspended_author]
    it_behaves_like "disallowed roles", to: %i[admin other_users]
  end

  describe "subscriptions?" do
    let(:policy_method) { :subscriptions? }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "permitted roles", to: %i[super_admin suspended_author]
    it_behaves_like "disallowed roles", to: %i[admin org_admin other_users]
  end

  %i[admin_unpublish? admin_featured_toggle?].each do |method_name|
    describe "admin_unpublish?" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "permitted roles", to: %i[super_admin admin]
      it_behaves_like "disallowed roles", to: %i[org_admin author other_users]
    end
  end

  %i[destroy? delete_confirm? discussion_lock_confirm? discussion_unlock_confirm?].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "permitted roles", to: %i[super_admin admin org_admin suspended_author]
      it_behaves_like "disallowed roles", to: [:other_users]
    end
  end
end
