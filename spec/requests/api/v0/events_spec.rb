require "rails_helper"

RSpec.describe "Api::V0::Events", type: :request do
  let!(:admin) { create(:user).tap { |u| u.add_role(:super_admin) } }
  let!(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:admin_headers) { { "api-key" => admin_api_secret.secret, "content-type" => "application/json" } }

  let!(:user) { create(:user) }
  let!(:user_api_secret) { create(:api_secret, user: user) }
  let!(:user_headers) { { "api-key" => user_api_secret.secret, "content-type" => "application/json" } }

  let!(:published_event) { create(:event, published: true, bg_color_hex: "#3B49DF", elevated: true) }
  let!(:draft_event) { create(:event, published: false) }

  describe "GET /api/events" do
    context "when unauthenticated" do
      it "returns only published events" do
        get "/api/events"
        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        expect(json.count).to eq(1)
        expect(json.first["id"]).to eq(published_event.id)
        expect(json.first["bg_color_hex"]).to eq("#3B49DF")
        expect(json.first["elevated"]).to be(true)
      end
    end

    context "when authenticated as basic user" do
      it "returns only published events" do
        get "/api/events", headers: user_headers
        json = JSON.parse(response.body)
        expect(json.count).to eq(1)
      end
    end

    context "when authenticated as an administrator" do
      it "returns all events including drafts" do
        get "/api/events", headers: admin_headers
        json = JSON.parse(response.body)
        expect(json.count).to eq(2)
      end
    end
  end

  describe "GET /api/events/:id" do
    context "when requesting a published event" do
      it "returns the event" do
        get "/api/events/#{published_event.id}"
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(published_event.id)
        expect(json["social_image_url"]).to be_present
      end
    end

    context "when requesting a draft event" do
      it "returns 404 for guests" do
        get "/api/events/#{draft_event.id}"
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for basic users" do
        get "/api/events/#{draft_event.id}", headers: user_headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns the event for administrators" do
        get "/api/events/#{draft_event.id}", headers: admin_headers
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /api/events" do
    let(:valid_params) do
      {
        event: {
          title: "New Stream",
          event_name_slug: "new-stream",
          event_variation_slug: "v1",
          start_time: 1.day.from_now,
          end_time: 2.days.from_now,
          type_of: "live_stream",
          primary_stream_url: "https://twitch.tv/ThePracticalDev",
          bg_color_hex: "#0D9488",
          elevated: true,
          published: false
        }
      }.to_json
    end

    it "blocks unauthenticated requests" do
      post "/api/events", params: valid_params, headers: { "content-type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "blocks basic users" do
      post "/api/events", params: valid_params, headers: user_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "allows administrators to create events with visual configuration" do
      expect {
        post "/api/events", params: valid_params, headers: admin_headers
      }.to change(Event, :count).by(1)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["bg_color_hex"]).to eq("#0D9488")
      expect(json["elevated"]).to be(true)
    end
  end

  describe "PUT /api/events/:id" do
    it "allows administrators to update events" do
      put "/api/events/#{published_event.id}",
          params: { event: { title: "Renamed Title", bg_color_hex: "#7C3AED" } }.to_json,
          headers: admin_headers

      expect(response).to have_http_status(:success)
      expect(published_event.reload.title).to eq("Renamed Title")
      expect(published_event.bg_color_hex).to eq("#7C3AED")
    end
  end

  describe "DELETE /api/events/:id" do
    it "allows administrators to delete events" do
      expect {
        delete "/api/events/#{draft_event.id}", headers: admin_headers
      }.to change(Event, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
