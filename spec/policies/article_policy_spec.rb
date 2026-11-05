# spec/policies/article_policy_spec.rb

require "rails_helper"

RSpec.describe ArticlePolicy do
  subject(:method_call) { policy.public_send(policy_method) }

  let(:instantiated_users) { {} }
  let(:organization) { instantiated_users[:org_admin]&.organizations&.first }

  let(:org_admin) { instantiated_users[:org_admin] = create(:user, :without_profile, :org_admin) }
  let(:anyone) { create(:user, :without_profile) }
  let(:super_admin) { create(:user, :without_profile, :super_admin) }
  let(:suspended_user) { instantiated_users[:author] = create(:user, :without_profile, :suspended) }
  let(:admin) { create(:user, :without_profile, :admin) }
  let(:trusted) { create(:user, :without_profile, :trusted) }
  let(:other_users) { create(:user, :without_profile) }
  let(:users_scope) { User.where(id: [super_admin.id, author.id, suspended_user.id]) }
  let(:author) { instantiated_users[:author] = create(:user, :without_profile) }
  let(:moderator) { create(:user, :without_profile, :super_moderator) }
  let(:tag_mod) { create(:user, :without_profile, :tag_moderator) }
  let(:tagmod_tag) { tag_mod.roles.find_by(name: "tag_moderator").resource }
  let(:random_tag) { create(:tag, name: "randomtag") }

  let(:resource) do
    build(:article, user_id: instantiated_users[:author]&.id || -1, organization: organization, with_tags: false)
  end
  let(:policy) { described_class.new(user, resource) }

  # Builds an ArticlePolicy for the given role symbol and aligns resource ownership/organization.
  def policy_for_role(role)
    role_user = role == :suspended_author ? suspended_user : public_send(role)
    resource.user_id = %i[author suspended_author].include?(role) ? role_user.id : -1
    resource.organization = role == :org_admin ? role_user.organizations.first : nil
    described_class.new(role_user, resource)
  end

  describe ".scope_users_authorized_to_action" do
    before do
      super_admin
      author
      suspended_user
    end

    context "when limit_post_creation_to_admins is true" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(true) }

      it "omits suspended and regular users" do
        results = described_class.scope_users_authorized_to_action(users_scope: users_scope, action: :create?).to_a
        expect(results).to contain_exactly(super_admin)
      end
    end

    context "when limit_post_creation_to_admins is false" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false) }

      it "omits only suspended users" do
        results = described_class.scope_users_authorized_to_action(users_scope: users_scope, action: :create?).to_a
        expect(results).to contain_exactly(author, super_admin)
      end
    end

    #
    # NEW: Test what happens if we're in a root subforem
    #
    context "when is_root_subforem? is true" do
      before do
        allow(described_class).to receive_messages(
          limit_post_creation_to_admins?: false,
          is_root_subforem?: true,
        )
      end

      it "returns users authorized to create in a root subforem" do
        results = described_class.scope_users_authorized_to_action(users_scope: users_scope, action: :create?).to_a
        expect(results.map(&:id)).to eq users_scope.with_any_role(:admin, :super_admin).map(&:id)
      end

      it "returns an empty result for create actions when no admins" do
        users_scope.with_any_role(:admin, :super_admin).each do |u|
          u.remove_role(:super_admin)
          u.remove_role(:admin)
        end
        results = described_class.scope_users_authorized_to_action(users_scope: users_scope, action: :create?).to_a
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
      before { allow(described_class).to receive(:is_root_subforem?).and_return(true) }

      it "returns true to hide the DOM regardless of limit_post_creation_to_admins?", :aggregate_failures do
        allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false)
        expect(described_class.include_hidden_dom_class_for?(query: :create?)).to be(true)

        allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(true)
        expect(described_class.include_hidden_dom_class_for?(query: :create?)).to be(true)
      end
    end
  end

  describe "#feed?" do
    let(:policy_method) { :feed? }
    let(:user) { build(:user) }

    it { is_expected.to be_truthy }
  end

  describe "#create? and #new?" do
    let(:policy_method) { %i[create? new?] }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "it requires a user in good standing"
    it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: false
    it_behaves_like "permitted roles", to: %i[super_admin admin], limit_post_creation_to_admins?: true
    it_behaves_like "disallowed roles", to: %i[anyone], limit_post_creation_to_admins?: true

    context "when is_root_subforem? is true" do
      let(:user) { author }

      before do
        allow(described_class).to receive_messages(
          is_root_subforem?: true,
          limit_post_creation_to_admins?: false,
        )
      end

      it "returns false regardless of user role", :aggregate_failures do
        policy_method.each do |method_name|
          expect(policy.public_send(method_name)).to be(false)
        end
      end
    end
  end

  describe "#preview? and #has_existing_articles_or_can_create_new_ones?" do
    let(:policy_method) { %i[preview? has_existing_articles_or_can_create_new_ones?] }

    it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: false
    it_behaves_like "permitted roles", to: %i[super_admin admin], limit_post_creation_to_admins?: true
    it_behaves_like "disallowed roles", to: %i[anyone], limit_post_creation_to_admins?: true

    context "when user has published articles" do
      before { create(:article, published: true, user: anyone, with_tags: false, with_main_image: false) }

      it "permits anyone regardless of limit_post_creation_to_admins?", :aggregate_failures do
        [false, true].each do |limit|
          allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(limit)
          expect(policy_for_role(:anyone)).to be_preview.and be_has_existing_articles_or_can_create_new_ones
        end
      end
    end

    context "when user has only unpublished articles" do
      before { create(:article, published: false, user: anyone, with_tags: false, with_main_image: false) }

      it "permits anyone across limit_post_creation_to_admins? and root subforem states", :aggregate_failures do
        [{ limit_post_creation_to_admins?: false }, { limit_post_creation_to_admins?: true },
         { is_root_subforem?: true }].each do |stubs|
          allow(described_class).to receive_messages(**stubs)
          expect(policy_for_role(:anyone)).to be_preview.and be_has_existing_articles_or_can_create_new_ones
        end
      end
    end

    context "when user has no published articles" do
      before { user.articles.delete_all }

      it_behaves_like "permitted roles", to: %i[anyone], limit_post_creation_to_admins?: false
      it_behaves_like "disallowed roles", to: %i[anyone], limit_post_creation_to_admins?: true
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

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "permitted roles", to: %i[super_admin admin moderator tag_mod]
    it_behaves_like "disallowed roles", to: %i[org_admin author other_users]
  end

  describe "#tag_moderator_eligible?" do
    subject(:policy) { described_class.new(tag_mod, resource) }

    context "when article includes tagmod_tag, has no room for more tags, and no relevant adjustments" do
      let(:resource) { build(:article, user_id: -1, tags: "tagtwo, tagthree, tagfour, #{tagmod_tag}") }

      it { is_expected.to be_tag_moderator_eligible }
    end

    context "when article has room for more tags and no relevant adjustments" do
      let(:resource) { build(:article, user_id: -1, tags: "tagtwo, tagthree, #{tagmod_tag}") }

      it { is_expected.to be_tag_moderator_eligible }
    end

    context "when an irrelevant tag has been adjusted" do
      let(:resource) { create(:article, user: tag_mod, tags: "tagtwo, tagthree, #{random_tag}, #{tagmod_tag}") }

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
      let(:resource) { build(:article, user_id: -1, tags: "tagtwo, tagthree, tagfour, tagfive") }

      it { is_expected.to be_tag_moderator_eligible }
    end

    context "when tag moderator's tag has been adjusted" do
      let(:resource) { create(:article, user: tag_mod, tags: "tagtwo, tagthree, tagfour, #{tagmod_tag}") }

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

      it { is_expected.not_to be_tag_moderator_eligible }
    end
  end

  describe "#update? and #edit?" do
    let(:policy_method) { %i[update? edit?] }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "it requires a user in good standing"
    it_behaves_like "permitted roles", to: %i[super_admin admin org_admin]
    it_behaves_like "disallowed roles", to: [:other_users]
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

  describe "#revoke_publication? and its moderator action aliases" do
    let(:policy_method) do
      %i[
        admin_unpublish? admin_featured_toggle? revoke_publication? toggle_featured_status?
        can_adjust_any_tag? can_perform_moderator_actions?
      ]
    end

    context "when published article" do
      let(:resource) { super().tap { |article| article.published = true } }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "permitted roles", to: %i[super_admin admin moderator]
      it_behaves_like "disallowed roles", to: %i[org_admin author other_users]
    end

    context "when unpublished article" do
      let(:resource) { super().tap { |article| article.assign_attributes(published: false, published_at: nil) } }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "permitted roles", to: %i[]
      it_behaves_like "disallowed roles", to: %i[super_admin admin moderator org_admin author other_users]
    end
  end

  describe "#destroy?, #delete_confirm?, #discussion_lock_confirm?, and #discussion_unlock_confirm?" do
    let(:policy_method) { %i[destroy? delete_confirm? discussion_lock_confirm? discussion_unlock_confirm?] }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "permitted roles", to: %i[super_admin admin org_admin suspended_author]
    it_behaves_like "disallowed roles", to: [:other_users]
  end
end
