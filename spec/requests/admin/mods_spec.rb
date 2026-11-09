require "rails_helper"

RSpec.describe "/admin/moderation/mods" do
  let!(:admin) { create(:user, :admin) }
  let!(:regular_user) { create(:user) }
  let!(:moderator) { create(:user, :trusted) }

  describe "GET /admin/moderation/mods" do
    before do
      sign_in admin
    end

    context "when the user is a single resource admin" do
      let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Mod) }

      before do
        sign_in single_resource_admin
        get admin_mods_path
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
          get admin_mods_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the are no matching mods" do
      it "displays an warning" do
        get "#{admin_mods_path}?search=no-results&state=tag_moderator"
        expect(response.body).to include("There are no mods matching your search criteria")
      end
    end

    it "displays mod user" do
      get admin_mods_path
      expect(response.body).to include(moderator.username)
    end

    it "does not display non-mod" do
      get admin_mods_path
      expect(response.body).not_to include(regular_user.username)
    end

    it "lists regular users as potential mods" do
      get "#{admin_mods_path}?state=potential"
      expect(response.body).to include(regular_user.username)
    end

    it "does not list mods as potential mods" do
      get "#{admin_mods_path}?state=potential"
      expect(response.body).not_to include(moderator.username)
    end

    it "uses countless pagination without executing COUNT(*) or duplicate existence queries" do
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        queries << payload[:sql] unless payload[:name] == "SCHEMA"
      end

      get admin_mods_path(state: "potential")
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(response).to have_http_status(:ok)
      mod_queries = queries.select { |sql| sql.include?("NOT EXISTS") }
      expect(mod_queries.size).to eq(1)
      expect(queries.none? { |sql| sql.match?(/SELECT COUNT\(\*\) FROM "users"/i) }).to be(true)
      expect(queries.none? { |sql| sql.match?(/SELECT 1 AS one FROM "users"/i) }).to be(true)
    end

    it "renders previous and next page links and handles nil last_comment_at" do
      regular_user.update_column(:last_comment_at, nil)

      get admin_mods_path(state: "potential", page: 2)
      expect(response).to have_http_status(:ok)

      get admin_mods_path(state: "potential")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(regular_user.username)
    end
  end

  describe "PUT /admin/moderation/mods" do
    before do
      sign_in admin
    end

    it "displays mod user" do
      put admin_mod_path(regular_user.id)
      expect(regular_user.reload.trusted?).to be true
    end
  end
end
