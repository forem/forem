require "rails_helper"

RSpec.describe "/internal/mods", type: :request do
  let(:super_admin)   { create(:user, :super_admin) }
  let(:regular_user)  { create(:user) }

  describe "GET /internal/mods" do
    before do
      sign_in super_admin
    end

    context "when the user is a single resource admin" do
      let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Mod) }

      before do
        sign_in single_resource_admin
        get "/internal/mods"
      end

      it "allows the request" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user is a not an admin" do
      before do
        sign_in regular_user
      end

      it "blocks the request" do
        expect do
          get "/internal/mods"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
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
