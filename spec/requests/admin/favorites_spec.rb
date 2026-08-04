require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/favorites" do
  # The page is user/role data, so it authorizes against User.
  it_behaves_like "an InternalPolicy dependant request", User do
    let(:request) { get admin_favorites_path }
  end

  describe "GET /admin/favorites" do
    let(:admin) { create(:user, :super_admin) }
    let(:leader) { create(:user) }

    before do
      Rails.cache.clear
      sign_in admin
    end

    it "renders the impact leaderboard for a leader with favorited content" do
      article = create(:article)
      article.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current, page_views_count: 7)

      get admin_favorites_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(leader.username)
    end

    it "renders the empty state when nothing has been favorited" do
      get admin_favorites_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("views.admin.favorites.leaderboard.empty"))
    end
  end
end
