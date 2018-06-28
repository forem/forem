require "rails_helper"

RSpec.describe AdminPolicy do
  subject { described_class }

  permissions :show? do
    context "non admin" do
    let(:user) {build(:user)}
      it "should not allow someone without admin privileges to do continue" do
        expect(subject).not_to permit(user)
      end
    end

    context "admin" do
    let(:user) {build(:user, :super_admin)}
      it "allow someone with admin privileges to continue" do
        expect(subject).to permit(user)
      end
    end
  end
end
