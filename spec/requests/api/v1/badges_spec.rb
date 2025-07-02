require "rails_helper"

RSpec.describe "/api/badges", type: :request do
  let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }
  let!(:badge) { create(:badge, allow_multiple_awards: false) }
  let(:tiny_gif_data) do
    "GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xFF\xFF\xFF!\xF9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x01D\x00;"
  end

  describe "GET /api/badges" do
    context "when unauthorized (not an admin)" do
      let(:user) { create(:user) }
      let(:api_secret) { create(:api_secret, user: user) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "rejects requests from regular users" do
        get api_badges_path, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorized (as an admin)" do
      let!(:admin) { create(:user, :admin) }
      let(:api_secret) { create(:api_secret, user: admin) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }
      let!(:badges) { create_list(:badge, 51) }

      it "returns a paginated list of 50 badges" do
        get api_badges_path, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(50)
      end
    end
  end

  describe "GET /api/badges/:id" do
    context "when authorized (as an admin)" do
      let!(:admin) { create(:user, :admin) }
      let(:api_secret) { create(:api_secret, user: admin) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "returns the specified badge" do
        get api_badge_path(badge.id), headers: headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(badge.id)
      end
    end
  end

  describe "POST /api/badges" do
    let(:valid_params) do
      {
        badge: {
          title: "Test Badge",
          description: "A badge for testing",
          remote_badge_image_url: "https://example.com/image.png",
          credits_awarded: 0,
          allow_multiple_awards: true
        }
      }
    end

    context "when authorized (as an admin)" do
      let!(:admin) { create(:user, :admin) }
      let(:api_secret) { create(:api_secret, user: admin) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "creates a new badge with valid params" do
        stub_request(:get, "https://example.com/image.png").to_return(status: 200, body: tiny_gif_data)

        expect do
          post api_badges_path, params: valid_params, headers: headers
        end.to change(Badge, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(Badge.last.allow_multiple_awards).to be true
      end
    end
  end

  describe "PATCH /api/badges/:id" do
    let(:update_params) do
      {
        badge: {
          title: "Updated Badge Title",
          allow_multiple_awards: true
        }
      }
    end

    context "when authorized (as an admin)" do
      let!(:admin) { create(:user, :admin) }
      let(:api_secret) { create(:api_secret, user: admin) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "updates the badge with valid params" do
        patch api_badge_path(badge.id), params: update_params, headers: headers

        expect(response).to have_http_status(:ok)
        reloaded_badge = badge.reload
        expect(reloaded_badge.title).to eq("Updated Badge Title")
        expect(reloaded_badge.allow_multiple_awards).to be true
      end

      it "does not update the badge with invalid params" do
        invalid_params = { badge: { title: "" } }
        patch api_badge_path(badge.id), params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/badges/:id" do
    context "when unauthorized (not an admin)" do
      let(:user) { create(:user) }
      let(:api_secret) { create(:api_secret, user: user) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

      it "rejects the request" do
        delete api_badge_path(badge.id), headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorized (as an admin)" do
      let!(:admin) { create(:user, :admin) }
      let(:api_secret) { create(:api_secret, user: admin) }
      let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }
      let!(:badge_to_delete) { create(:badge) }

      it "deletes the badge" do
        expect do
          delete api_badge_path(badge_to_delete.id), headers: headers
        end.to change(Badge, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end