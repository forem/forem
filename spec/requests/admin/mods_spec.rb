require "rails_helper"

RSpec.describe "/admin/mods", type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:regular_user) { create(:user) }
  let!(:moderator) { create(:user, :trusted) }

  describe "GET /admin/mods" do
    before do
      sign_in admin
    end

    context "when the user is a single resource admin" do
      let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Mod) }

      before do
        sign_in single_resource_admin
        get "/admin/mods"
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
          get "/admin/mods"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the are no matching mods" do
      it "displays an warning" do
        get "/admin/mods?search=no-results&state=tag_moderator"
        expect(response.body).to include("There are no mods matching your search criteria")
      end
    end

    it "displays mod user" do
      get "/admin/mods"
      expect(response.body).to include(moderator.username)
    end

    it "does not display non-mod" do
      get "/admin/mods"
      expect(response.body).not_to include(regular_user.username)
    end

    it "lists regular users as potential mods" do
      get "/admin/mods?state=potential"
      expect(response.body).to include(regular_user.username)
    end

    it "does not list mods as potential mods" do
      get "/admin/mods?state=potential"
      expect(response.body).not_to include(moderator.username)
    end
  end

  describe "PUT /admin/mods" do
    before do
      sign_in admin
    end

    it "displays mod user" do
      put "/admin/mods/#{regular_user.id}"
      expect(regular_user.reload.has_role?(:trusted)).to eq true
    end
  end
end
