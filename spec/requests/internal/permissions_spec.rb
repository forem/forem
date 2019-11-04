require "rails_helper"

RSpec.describe "/internal/permissions", type: :request do
  let(:super_admin)   { create(:user, :super_admin) }
  let(:regular_user)  { create(:user) }

  describe "GET /internal/mods" do
    before do
      sign_in super_admin
    end

    it "displays admin users" do
      regular_user.add_role(:admin)
      get "/internal/permissions"
      expect(response.body).to include(regular_user.username)
    end

    it "does not display non-admin" do
      get "/internal/permissions"
      expect(response.body).not_to include(regular_user.username)
    end
  end
end
