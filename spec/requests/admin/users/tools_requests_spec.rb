require "rails_helper"

RSpec.describe "/admin/users/:user_id/tools", type: :request do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "#show" do
    let(:user) { create(:user) }

    it "returns not found for non existing users" do
      expect { get admin_user_tools_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders successfully" do
      get admin_user_tools_path(user)

      expect(response).to have_http_status(:ok)
    end
  end
end
