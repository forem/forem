require "rails_helper"

describe Admin::OrganizationsHelper do
  describe "#deletion_modal_error_message" do
    let(:organization) { create(:organization) }
    let(:super_admin) { create(:user, :super_admin) }
    let(:admin) { create(:user, :admin) }

    context "when the current user is not a super admin" do
      before { allow(helper).to receive(:current_user).and_return(admin) }

      it "returns the appropriate error messsage" do
        error_message = helper.deletion_modal_error_message(organization)
        expect(error_message).to eq("Only Super Admins are allowed to delete organizations.")
      end
    end

    context "when there are credits associated to an organization" do
      before { allow(helper).to receive(:current_user).and_return(super_admin) }

      it "returns the appropriate error message without loading the credits association" do
        Credit.add_to(organization, 10)
        allow(organization).to receive(:credits).and_call_original

        error_message = helper.deletion_modal_error_message(organization)
        expect(error_message).to eq("You cannot delete an organization that has associated credits.")
        expect(organization).not_to have_received(:credits)
      end
    end
  end
end
