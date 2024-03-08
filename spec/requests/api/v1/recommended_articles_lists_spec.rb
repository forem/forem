require "rails_helper"

RSpec.describe "Api::V1::RecommendedArticlesLists" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  let(:list_params) do
    {
      name: "Sample List",
      placement_area: "main_feed",
      expires_at: 1.week.from_now,
      user_id: user.id,
      article_ids: [article1.id, article2.id]
    }
  end

  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:article1) { create(:article) }
  let(:article2) { create(:article) }
  let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }

  shared_context "when user is authorized" do
    before { user.add_role(:admin) }
  end

  describe "GET /api/v1/recommended_articles_lists" do
    context "when authenticated and authorized" do
      include_context "when user is authorized"

      it "returns json response with all recommended article lists" do
        get api_recommended_articles_lists_path, headers: auth_header
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        # Expectations regarding the content of the response
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        get api_recommended_articles_lists_path, headers: v1_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/recommended_articles_lists/:id" do
    let(:existing_list) { create(:recommended_articles_list, user: user) }

    context "when authenticated and authorized" do
      include_context "when user is authorized"

      it "returns json response with the specified recommended article list" do
        get api_recommended_articles_list_path(existing_list.id), headers: auth_header
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        get api_recommended_articles_list_path(existing_list.id), headers: v1_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/recommended_articles_lists" do
    context "when authenticated and authorized" do
      include_context "when user is authorized"

      it "creates a new recommended articles list" do
        expect do
          post api_recommended_articles_lists_path, params: list_params.to_json, headers: auth_header
        end.to change(RecommendedArticlesList, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.media_type).to eq("application/json")
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        post api_recommended_articles_lists_path, params: list_params.to_json, headers: v1_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /api/v1/recommended_articles_lists/:id" do
    let(:existing_list) { create(:recommended_articles_list, user: user) }

    context "when authenticated and authorized" do
      include_context "when user is authorized"

      it "updates an existing recommended articles list" do
        user.add_role(:admin)
        put api_recommended_articles_list_path(existing_list.id), params: list_params
          .merge(name: "Updated List").to_json, headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        # Assertions for the updated attributes
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        put api_recommended_articles_list_path(existing_list.id), params: list_params.to_json, headers: v1_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
