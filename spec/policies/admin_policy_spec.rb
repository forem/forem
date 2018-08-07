require "rails_helper"

RSpec.describe AdminPolicy do
  subject { described_class }

  permissions :show? do
    context "when regular user" do
      let(:user) { build(:user) }

      it "does not allow someone without admin privileges to do continue" do
        expect(subject).not_to permit(user) # rubocop:disable RSpec/NamedSubject
      end
    end

    context "when admin" do
      let(:user) { build(:user, :super_admin) }

      it "allow someone with admin privileges to continue" do
        expect(subject).to permit(user) # rubocop:disable RSpec/NamedSubject
      end
    end
  end
end
