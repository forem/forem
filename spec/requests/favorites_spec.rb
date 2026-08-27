require "rails_helper"

RSpec.describe "Favorites" do
  let(:leader) { create(:user, :community_leader_level_1) }
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }

  describe "POST /favorites" do
    context "when signed in as a community leader" do
      before { sign_in leader }

      it "favorites the article" do
        post favorites_path, params: { favoritable_type: "Article", favoritable_id: article.id }, as: :json

        expect(response).to have_http_status(:ok)
        expect(article.reload.favorited_by_user_id).to eq(leader.id)
      end

      it "returns an already_favorited error when claimed" do
        other_leader = create(:user, :community_leader_level_1)
        article.update!(favorited_by_user_id: other_leader.id, favorited_at: Time.current)

        post favorites_path, params: { favoritable_type: "Article", favoritable_id: article.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["code"]).to eq("already_favorited")
        expect(response.parsed_body["error"]).to be_present
        # The original favoriter is untouched.
        expect(article.reload.favorited_by_user_id).to eq(other_leader.id)
      end

      it "returns an error for an ineligible article" do
        draft = create(:article, user: author, published: false)

        post favorites_path, params: { favoritable_type: "Article", favoritable_id: draft.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["code"]).to eq("cannot_favorite")
        expect(draft.reload.favorited_by_user_id).to be_nil
      end

      it "returns an error for an unknown favoritable" do
        post favorites_path, params: { favoritable_type: "Article", favoritable_id: 0 }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["code"]).to eq("cannot_favorite")
      end

      it "returns an error for an unsupported favoritable type" do
        post favorites_path, params: { favoritable_type: "User", favoritable_id: author.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["code"]).to eq("cannot_favorite")
      end
    end

    context "when signed in as a non-leader with no earned credits" do
      before { sign_in create(:user) }

      it "reports the exhausted allowance" do
        post favorites_path, params: { favoritable_type: "Article", favoritable_id: article.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["code"]).to eq("no_allowance")
        expect(article.reload.favorited_by_user_id).to be_nil
      end
    end

    context "when signed in as a non-leader holding earned credits" do
      let(:spender) { create(:user, earned_favorites_count: 1) }

      before { sign_in spender }

      it "favorites and spends the credit" do
        post favorites_path, params: { favoritable_type: "Article", favoritable_id: article.id }, as: :json

        expect(response).to have_http_status(:ok)
        expect(article.reload.favorited_by_user_id).to eq(spender.id)
        expect(spender.reload.earned_favorites_count).to eq(0)
      end
    end

    context "when signed out" do
      it "does not favorite" do
        post favorites_path, params: { favoritable_type: "Article", favoritable_id: article.id }, as: :json

        expect(response).not_to have_http_status(:ok)
        expect(article.reload.favorited_by_user_id).to be_nil
      end
    end
  end

  describe "the favorite control mount node on the article page" do
    before do
      FeatureFlag.add(:community_favorites)
      FeatureFlag.enable(:community_favorites)
    end

    after { FeatureFlag.remove(:community_favorites) }

    # Data is user-agnostic and cache-safe. The Preact component decides
    # client-side visibility.
    it "renders the mount node with the article's favoritable data" do
      sign_in create(:user)
      get article.path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("data-favorite-control")
      expect(response.body).to include("data-favoritable-type=\"Article\"")
      expect(response.body).to include("data-favoritable-id=\"#{article.id}\"")
    end

    it "renders no mount node when the feature flag is disabled" do
      FeatureFlag.disable(:community_favorites)
      sign_in create(:user)

      get article.path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("data-favorite-control")
    end
  end
end
