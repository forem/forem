require "rails_helper"

RSpec.describe "/internal/mods", type: :request do
  let(:super_admin)   { create(:user, :super_admin) }
  let(:regular_user)  { create(:user) }

  describe "GET /internal/mods" do
    before do
      sign_in super_admin
    end

    it "displays mod user" do
      regular_user.add_role(:trusted)
      get "/internal/mods"
      expect(response.body).to include(regular_user.username)
    end
    it "does not display non-mod" do
      get "/internal/mods"
      expect(response.body).not_to include(regular_user.username)
    end
  end

  describe "PUT /internal/mods" do
    before do
      sign_in super_admin
    end

    it "displays mod user" do
      put "/internal/mods/#{regular_user.id}"
      expect(regular_user.reload.has_role?(:trusted)).to eq true
    end
  end
end
