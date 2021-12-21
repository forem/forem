require "rails_helper"

RSpec.describe InternalPolicy, type: :policy do
  let(:internal_policy) { described_class }

  permissions :access? do
    let(:user) { instance_double(User) }

    context "when user does not have administrative access (to the record)" do
      before { allow(user).to receive(:administrative_access_to?).and_return(false) }

      it "does not permit the user" do
        expect(internal_policy).not_to permit(user)
      end
    end

    context "when user has administrative access (to the record)" do
      before { allow(user).to receive(:administrative_access_to?).and_return(true) }

      it "does not permit the user" do
        expect(internal_policy).to permit(user)
      end
    end
  end
end
