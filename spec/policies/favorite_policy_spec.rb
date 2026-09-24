require "rails_helper"

RSpec.describe FavoritePolicy do
  subject(:policy) { described_class.new(user, article) }

  let(:article) { build_stubbed(:article) }

  describe "#create?" do
    context "with a community leader" do
      let(:user) { create(:user, :community_leader_level_1) }

      it "permits" do
        expect(policy.create?).to be true
      end
    end

    context "with a regular user" do
      let(:user) { create(:user) }

      it "permits" do
        expect(policy.create?).to be true
      end
    end

    context "with no user" do
      let(:user) { nil }

      it "raises UserRequiredError" do
        expect { policy.create? }.to raise_error(ApplicationPolicy::UserRequiredError)
      end
    end

    context "with a suspended leader" do
      let(:user) { create(:user, :community_leader_level_1, :suspended) }

      it "raises UserSuspendedError" do
        expect { policy.create? }.to raise_error(ApplicationPolicy::UserSuspendedError)
      end
    end

    context "with a suspended user" do
      let(:user) { create(:user, :suspended, earned_favorites_count: 5) }

      it "raises UserSuspendedError" do
        expect { policy.create? }.to raise_error(ApplicationPolicy::UserSuspendedError)
      end
    end
  end
end
