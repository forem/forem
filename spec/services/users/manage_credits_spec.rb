require "rails_helper"

RSpec.describe Users::ManageCredits, type: :service do
  describe "When the the service is called" do
    subject(:invoke_service) { described_class.call(user, user_params) }

    let(:user) { create(:user) }
    let(:organization) { create(:organization) }

    context "when user add the proper amount of credits" do
      let(:user_params) do
        { add_credits: "4" }
      end

      before { invoke_service }

      it { expect(user.reload.credits_count).to eq 4 }
      it { expect(user.reload.unspent_credits_count).to eq 4 }
    end

    context "when user removes the proper amount of credits" do
      let(:user_params) do
        { remove_credits: "4" }
      end

      before do
        Credit.add_to(user, 10)
        invoke_service
      end

      it { expect(user.reload.credits_count).to eq 6 }
      it { expect(user.reload.unspent_credits_count).to eq 6 }
    end

    context "when remove the proper amount of credits for organizations" do
      let(:user_params) do
        { remove_org_credits: "6", organization_id: organization.id }
      end

      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        Credit.add_to(organization, 10)
        invoke_service
      end

      it { expect(organization.reload.credits_count).to eq 4 }
      it { expect(organization.reload.unspent_credits_count).to eq 4 }
    end

    context "when adds the proper amount of credits for organizations" do
      let(:user_params) do
        { add_org_credits: "7", organization_id: organization.id }
      end

      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        invoke_service
      end

      it { expect(organization.reload.credits_count).to eq 7 }
      it { expect(organization.reload.unspent_credits_count).to eq 7 }
    end
  end
end
