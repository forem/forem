require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
  end

  describe "PATCH #update" do
    context "with valid params" do
      before do
        path = "/admin/users/" + super_admin.id.to_s
        patch path, params: { user: { password: "strongpassword" } }
      end

      it "updates the user's password" do
        expect(response).to redirect_to "/admin/users/" + super_admin.id.to_s
      end
    end
  end
end
