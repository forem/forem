require "rails_helper"

RSpec.describe BadgePolicy do
  subject { described_class.new(user, :badge) }

  context "when user is a regular user" do
    let(:user) { create(:user) }

    it { is_expected.to forbid_actions(%i[api]) }
  end

  context "when user is an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_actions(%i[api]) }
  end

  context "when user is a super admin" do
    let(:user) { create(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[api]) }
  end

  context "when user is a single resource admin for Badge" do
    let(:user) { create(:user).tap { |u| u.add_role(:single_resource_admin, Badge) } }

    it { is_expected.to permit_actions(%i[api]) }
  end

  context "when user is a single resource admin for BadgeAchievement" do
    let(:user) { create(:user).tap { |u| u.add_role(:single_resource_admin, BadgeAchievement) } }

    it { is_expected.to forbid_actions(%i[api]) }
  end
end
