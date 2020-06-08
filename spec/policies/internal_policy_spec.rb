require "rails_helper"

RSpec.describe InternalPolicy, type: :policy do
  let(:internal_policy) { described_class }

  permissions :access? do
    it "does not allow someone without admin privileges to do continue" do
      expect(internal_policy).not_to permit(build(:user))
    end

    it "allow someone with admin privileges to continue" do
      expect(internal_policy).to permit(create(:user, :admin))
    end

    it "allow someone with super_admin privileges to continue" do
      expect(internal_policy).to permit(create(:user, :super_admin))
    end

    context "when tied to a resource" do
      let(:user) { create(:user) }

      it "grant access based on permitted resource" do
        user.add_role_synchronously(:single_resource_admin, Article)
        expect(internal_policy).to permit(user, Article)
      end

      it "does not grant cross resource access" do
        user.add_role_synchronously(:single_resource_admin, Article)
        expect(internal_policy).not_to permit(user, Comment)
      end
    end
  end
end
