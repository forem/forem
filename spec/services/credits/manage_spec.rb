require "rails_helper"

RSpec.describe Credits::Manage, type: :service do
  describe "When the the service is called" do
    subject(:invoke_service) { described_class.call(user, user_params) }

    let(:user) { create(:user) }
    let(:organization) { create(:organization) }

    context "when user add an amount of credits" do
      let(:user_params) do
        { add_credits: "4" }
      end

      it "adds user credits" do
        expect do
          invoke_service
        end.to change { user.reload.credits_count }.by(user_params[:add_credits].to_i)
      end
    end

    context "when user removes the proper amount of credits" do
      let(:user_params) do
        { remove_credits: "4" }
      end

      before do
        Credit.add_to(user, 10)
      end

      it "removes user credits" do
        expect do
          invoke_service
        end.to change { user.reload.credits_count }.by(user_params[:remove_credits].to_i * -1)
      end
    end

    context "when remove the proper amount of credits for organizations" do
      let(:user_params) do
        { remove_org_credits: "6", organization_id: organization.id }
      end

      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        Credit.add_to(organization, 10)
      end

      it "removes org credits" do
        expect do
          invoke_service
        end.to change { organization.reload.credits_count }.by(user_params[:remove_org_credits].to_i * -1)
      end
    end

    context "when adds an amount of credits for organizations" do
      let(:user_params) do
        { add_org_credits: "7", organization_id: organization.id }
      end

      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
      end

      it "adds org credits" do
        expect do
          invoke_service
        end.to change { organization.reload.credits_count }.by(user_params[:add_org_credits].to_i)
      end
    end
  end
end
