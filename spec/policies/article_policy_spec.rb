# spec/policies/article_policy_spec.rb

require "rails_helper"

RSpec.describe ArticlePolicy do
  subject(:method_call) { policy.public_send(policy_method) }

  let(:organization) { org_admin&.organizations&.first }

  let(:org_admin) { create(:user, :org_admin) }
  let(:anyone) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:suspended_user) { create(:user, :suspended) }
  let(:admin) { create(:user, :admin) }
  let(:trusted) { create(:user, :trusted) }
  let(:other_users) { create(:user) }
  let(:author) { create(:user) }
  let(:moderator) { create(:user, :super_moderator) }
  let(:tag_mod) { create(:user, :tag_moderator) }
  let(:tagmod_tag) { tag_mod.roles.find_by(name: "tag_moderator").resource }
  let(:random_tag) { create(:tag, name: "randomtag") }

  let(:resource) { build(:article, user: author, organization: organization) }
  let(:policy) { described_class.new(user, resource) }

  describe ".scope_users_authorized_to_action" do
    before do
      User.destroy_all
      super_admin
      author
      suspended_user
    end

    context "when limit_post_creation_to_admins is true" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(true) }

      it "omits suspended and regular users" do
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results).to contain_exactly(super_admin)
      end
    end

    context "when limit_post_creation_to_admins is false" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false) }

      it "omits only suspended users" do
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results).to contain_exactly(author, super_admin)
      end
    end

    #
    # NEW: Test what happens if we're in a root subforem
    #
    context "when is_root_subforem? is true" do
      before do
        allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false)
        allow(described_class).to receive(:is_root_subforem?).and_return(true)
      end

      it "returns users authorized to create in a root subforem" do
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results.map(&:id)).to eq User.with_any_role(:admin, :super_admin).map(&:id)
      end

      it "returns an empty result for create actions when no admins" do
        User.with_any_role(:admin, :super_admin).map { |u| u.remove_role(:super_admin); u.remove_role(:admin) }
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results).to be_empty
      end
    end
  end

  describe ".include_hidden_dom_class_for?" do
    [
      [true, :create?, true],
      [false, :create?, false],
      [true, :edit?, false],
      [false, :edit?, false],
    ].each do |limit, query, expected_value|
      context "when limit_post_creation_to_admins is #{limit} and query is #{query}" do
        subject { described_class.include_hidden_dom_class_for?(query: query) }

        before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(limit) }

        it { is_expected.to eq(expected_value) }
      end
    end

    context "when is_root_subforem? is true" do
      subject { described_class.include_hidden_dom_class_for?(query: :create?) }

      before do
        # Let's test the scenario with limit_post_creation_to_admins? = false
        # and also verify limit_post_creation_to_admins? = true scenario.
        allow(described_class).to receive(:is_root_subforem?).and_return(true)
      end

      context "and limit_post_creation_to_admins? is false" do
        before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false) }

        it "returns true to hide the DOM" do
          expect(described_class.include_hidden_dom_class_for?(query: :create?)).to eq(true)
        end
      end

      context "and limit_post_creation_to_admins? is true" do
        before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(true) }

        it "still returns true to hide the DOM" do
          expect(described_class.include_hidden_dom_class_for?(query: :create?)).to eq(true)
        end
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

      context "when is_root_subforem? is true" do
        let(:user) { author } # or any user
        before do
          allow(described_class).to receive(:is_root_subforem?).and_return(true)
          allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false)
        end

        it "returns false regardless of user role" do
          expect(method_call).to eq(false)
        end
      end
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
    it_behaves_like "permitted roles", to: %i[trusted super_admin admin], limit_post_creation_to_admins?: false
    it_behaves_like "disallowed roles", to: %i[author], limit_post_creation_to_admins?: false
    it_behaves_like "disallowed roles", to: %i[trusted super_admin admin], limit_post_creation_to_admins?: true
  end

  describe "#allow_tag_adjustment?" do
    let(:policy_method) { :allow_tag_adjustment? }
    let(:resource) { create(:article, tags: tagmod_tag, user: author, organization: organization) }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "permitted roles", to: %i[super_admin admin moderator tag_mod]
    it_behaves_like "disallowed roles", to: %i[org_admin author other_users]
  end

  describe "#tag_moderator_eligible?" do
    subject(:policy) { described_class.new(tag_mod, resource) }

    context "when article includes tagmod_tag, has no room for more tags, and no relevant adjustments" do
      let(:resource) { create(:article, tags: "tagtwo, tagthree, tagfour, #{tagmod_tag}") }

      it { is_expected.to be_tag_moderator_eligible }
    end

    context "when article has room for more tags and no relevant adjustments" do
      let(:resource) { create(:article, tags: "tagtwo, tagthree, #{tagmod_tag}") }

      it { is_expected.to be_tag_moderator_eligible }
    end

    context "when an irrelevant tag has been adjusted" do
      let(:resource) { create(:article, tags: "tagtwo, tagthree, #{random_tag}, #{tagmod_tag}") }

      it "is tag_moderator_eligible" do
        create(
          :tag_adjustment,
          user_id: super_admin.id,
          article_id: resource.id,
          tag_id: random_tag.id,
          tag_name: random_tag,
          adjustment_type: "removal",
        )
        expect(policy).to be_tag_moderator_eligible
      end
    end

    context "when article excludes tagmod_tag, has no room for more tags, and no relevant adjustments" do
      let(:resource) { create(:article, tags: "tagtwo, tagthree, tagfour, tagfive") }

      it { is_expected.to be_tag_moderator_eligible }
    end

    context "when tag moderator's tag has been adjusted" do
      let(:resource) { create(:article, tags: "tagtwo, tagthree, tagfour, #{tagmod_tag}") }

      it "is not tag_moderator_eligible" do
        create(
          :tag_adjustment,
          user_id: super_admin.id,
          article_id: resource.id,
          tag_id: tagmod_tag.id,
          tag_name: tagmod_tag,
          adjustment_type: "removal",
        )
        expect(policy).to be_tag_moderator_eligible
      end
    end

    context "when user is not a tag moderator" do
      subject(:policy) { described_class.new(anyone, resource) }

      let(:resource) { create(:article, tags: tagmod_tag.to_s) }

      it { is_expected.not_to be_tag_moderator_eligible }
    end
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

  %i[
    admin_unpublish? admin_featured_toggle? revoke_publication? toggle_featured_status?
    can_adjust_any_tag? can_perform_moderator_actions?
  ].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      context "when published article" do
        let(:resource) { create(:article, user: author, organization: organization) }

        it_behaves_like "it requires an authenticated user"
        it_behaves_like "permitted roles", to: %i[super_admin admin moderator]
        it_behaves_like "disallowed roles", to: %i[org_admin author other_users]
      end

      context "when unpublished article" do
        let(:resource) do
          build(:article, user: author, organization: organization, published: false, published_at: nil)
        end

        it_behaves_like "it requires an authenticated user"
        it_behaves_like "permitted roles", to: %i[]
        it_behaves_like "disallowed roles", to: %i[super_admin admin moderator org_admin author other_users]
      end
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
