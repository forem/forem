require "rails_helper"

RSpec.describe "admin/users/gdpr_delete_requests", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let!(:gdr) { create(:gdpr_delete_request, email: "user@dev.to") }

  before do
    sign_in(admin)
  end

  it "renders successfully" do
    get admin_users_gdpr_delete_requests_path
    expect(response).to be_successful
  end

  it "displays the gdpr delete requests" do
    get admin_users_gdpr_delete_requests_path
    expect(response.body).to include("user@dev.to")
  end

  it "destroys the gdpr delete request on confirmation" do
    expect do
      delete admin_users_gdpr_delete_request_path(gdr.id)
    end.to change(Users::GdprDeleteRequest, :count).by(-1)
  end
end
