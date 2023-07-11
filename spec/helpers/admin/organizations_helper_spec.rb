require "rails_helper"

Rspec.describe Admin::UsersHelper do
  describe "#deletion_modal_error_message" do
    let(:organization) { create(:organization) }
    let(:super_admin) { create(:user, :super_admin) }
    let(:admin) { create(:user, :admin) }

    context "when the current user is not a super admin" do
      before { allow(helper).to receive(:current_user).and_return(admin) }

      it "returns the appropriate error messsage" do
        error_message = helper.deletion_modal_error_message(organization)
        expect(error_message).to eq("You need super admin permissions.")
      end
    end

    context "when there are credits associated to an organization" do
      before { allow(helper).to receive(:current_user).and_return(super_admin) }

      it "returns the appropriate error messsage" do
        Credit.add_to(organization, 10)
        error_message = helper.deletion_modal_error_message(organization)
        expect(error_message).to eq("You cannot delete an organization that has existing credits.")
      end
    end
  end
end
