require "rails_helper"

RSpec.describe "Curation dashboard" do
  let(:leader) { create(:user, :community_leader_level_1) }

  describe "GET /curation" do
    context "when signed in as a community leader" do
      before { sign_in leader }

      it "defaults to the community picks section and displays allowance and explainer" do
        get curation_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("views.leadership.heading"))
        expect(response.body).to include(I18n.t("views.leadership.nav.community"))
        expect(response.body).to include(I18n.t("views.leadership.explainer.heading"))
      end

      it "shows gems picked in the past 24 hours by any curator" do
        other_curator = create(:user, :community_leader_level_1)
        recent_gem = create(:article, title: "Recent Gem Post")
        recent_gem.update_columns(favorited_by_user_id: other_curator.id, favorited_at: 2.hours.ago)

        old_gem = create(:article, title: "Old Gem Post")
        old_gem.update_columns(favorited_by_user_id: other_curator.id, favorited_at: 2.days.ago)

        get curation_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Recent Gem Post")
        expect(response.body).not_to include("Old Gem Post")
      end

      it "shows 'Start the discussion' CTA when a curated post has 0 comments" do
        gem_post = create(:article, comments_count: 0)
        gem_post.update_columns(favorited_by_user_id: leader.id, favorited_at: 1.hour.ago)

        get curation_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("views.leadership.cards.start_discussion"))
      end

      it "shows 'Further the discussion' CTA when a curated post has 1 or 2 comments" do
        gem_post = create(:article, comments_count: 2)
        gem_post.update_columns(favorited_by_user_id: leader.id, favorited_at: 1.hour.ago)

        get curation_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("views.leadership.cards.further_discussion"))
      end

      it "shows your gems in the 'yours' section" do
        my_gem = create(:article, title: "My Curated Article")
        my_gem.update_columns(favorited_by_user_id: leader.id, favorited_at: 3.days.ago)

        other_leader = create(:user, :community_leader_level_1)
        other_gem = create(:article, title: "Other Curated Article")
        other_gem.update_columns(favorited_by_user_id: other_leader.id, favorited_at: 3.days.ago)

        get curation_section_path("yours")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("views.leadership.nav.yours"))
        expect(response.body).to include("My Curated Article")
        expect(response.body).not_to include("Other Curated Article")
      end
    end

    context "when signed in as an admin curator" do
      let(:admin_curator) { create(:user, :admin, :community_leader_level_1) }

      before { sign_in admin_curator }

      it "renders unlimited gem picks allowance text" do
        get curation_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("views.leadership.allowance.unlimited_html"))
        expect(response.body).to include(I18n.t("views.leadership.allowance.unlimited_note"))
      end
    end

    context "when signed in as a non-leader" do
      it "returns 404" do
        sign_in create(:user)

        get curation_path

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when signed out" do
      it "does not render the dashboard" do
        get curation_path

        expect(response).not_to have_http_status(:ok)
      end
    end
  end

  describe "GET /leadership" do
    context "when signed in as a community leader" do
      before { sign_in leader }

      it "renders the curation dashboard identically" do
        get leadership_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("views.leadership.heading"))
      end
    end
  end
end
