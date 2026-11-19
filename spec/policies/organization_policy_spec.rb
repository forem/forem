require "rails_helper"

RSpec.describe OrganizationPolicy, type: :policy do
  subject(:organization_policy) { described_class.new(user, organization) }

  let(:organization) { build_stubbed(:organization) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when a non-org user" do
    let(:user) { build_stubbed(:user) }

    it { is_expected.to forbid_actions(%i[update analytics]) }
    it { is_expected.to permit_action(:create) }
  end

  context "when user is suspended" do
    let(:user) { build(:user, :suspended) }

    it { is_expected.to forbid_actions(%i[create update]) }
  end

  context "when user is an org admin of an org" do
    subject(:organization_policy) { described_class.new(user, org) }

    let(:user) { create(:user) }
    let(:org)  { create(:organization) }

    before do
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
    end

    it { is_expected.to permit_actions(%i[analytics update]) }
  end

  context "when user is a member of an org org" do
    subject(:organization_policy) { described_class.new(user, org) }

    let(:user) { create(:user) }
    let(:org)  { create(:organization) }

    before do
      create(:organization_membership, user: user, organization: org)
    end

    it { is_expected.to permit_actions(%i[analytics]) }
  end

  context "when user is a site admin but not an org member" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:update) }
  end

  context "when user is a super admin but not an org member" do
    let(:user) { create(:user, :super_admin) }

    it { is_expected.to permit_action(:update) }
  end

  context "when user is an org admin of another org" do
    subject(:organization_policy) { described_class.new(user, new_org) }

    let(:user) { create(:user) }
    let(:org)  { create(:organization) }
    let(:new_org) { build_stubbed(:organization) }

    before { create(:organization_membership, user: user, organization: org, type_of_user: "admin") }

    it { is_expected.to forbid_actions(%i[analytics update]) }
  end

  describe "#article_analytics?" do
    subject(:organization_policy) { described_class.new(user, org) }

    let(:user) { create(:user) }
    let(:org) { create(:organization) }

    after { FeatureFlag.remove(:org_article_analytics) }

    it "permits active members when the org feature is enabled" do
      create(:organization_membership, user: user, organization: org)
      FeatureFlag.enable(:org_article_analytics, FeatureFlag::Actor[org])

      expect(organization_policy).to permit_action(:article_analytics)
    end

    it "forbids active members when the org feature is disabled" do
      create(:organization_membership, user: user, organization: org)

      expect(organization_policy).to forbid_action(:article_analytics)
    end

    it "forbids non-members even when the feature is globally enabled" do
      FeatureFlag.enable(:org_article_analytics)

      expect(organization_policy).to forbid_action(:article_analytics)
    end
  end
end
