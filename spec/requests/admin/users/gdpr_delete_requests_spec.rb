require "rails_helper"

RSpec.describe "admin/users/gdpr_delete_requests", type: :request do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  context "with gdpr request" do
    let!(:gdr) { create(:gdpr_delete_request, email: "user@dev.to") }

    it "renders successfully" do
      get admin_users_gdpr_delete_requests_path
      expect(response).to be_successful
    end

    it "displays the gdpr delete requests" do
      get admin_users_gdpr_delete_requests_path
      expect(response.body).to include("user@dev.to")
    end

    it "displays the number of existing requests" do
      get admin_users_gdpr_delete_requests_path
      expect(response.body).to include("<span class=\"crayons-indicator crayons-indicator--critical\">1</span>")
    end

    it "destroys the gdpr delete request on confirmation" do
      expect do
        delete admin_users_gdpr_delete_request_path(gdr.id)
      end.to change(Users::GdprDeleteRequest, :count).by(-1)
    end

    it "creates a corresponding audit_log on confirmation" do
      expect do
        delete admin_users_gdpr_delete_request_path(gdr.id)
      end.to change(AuditLog, :count).by(1)
    end
  end

  context "without gdpr request" do
    it "doesn't display the number of existing requests" do
      get admin_users_gdpr_delete_requests_path
      expect(response.body).not_to include("<span class=\"crayons-indicator crayons-indicator--critical\">0</span>")
    end
  end
end
