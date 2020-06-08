require "rails_helper"

RSpec.describe AdminPolicy, type: :policy do
  let(:admin_policy) { described_class }

  permissions :show? do
    context "when regular user" do
      let(:user) { build_stubbed(:user) }

      it "does not allow someone without admin privileges to do continue" do
        expect(admin_policy).not_to permit(user)
      end
    end

    context "when admin" do
      let(:user) { create(:user, :super_admin) }

      it "allow someone with admin privileges to continue" do
        expect(admin_policy).to permit(user)
      end
    end
  end
end
