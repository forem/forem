require "rails_helper"

RSpec.describe "Api::V0::Events" do
  let!(:admin) { create(:user).tap { |u| u.add_role(:super_admin) } }
  let!(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:admin_headers) { { "api-key" => admin_api_secret.secret, "content-type" => "application/json" } }

  let!(:user) { create(:user) }
  let!(:user_api_secret) { create(:api_secret, user: user) }
  let!(:user_headers) { { "api-key" => user_api_secret.secret, "content-type" => "application/json" } }

  let!(:published_event) { create(:event, published: true) }
  let!(:draft_event) { create(:event, published: false) }

  describe "GET /api/events" do
    context "when unauthenticated" do
      it "returns only published events" do
        get "/api/events"
        expect(response).to have_http_status(:success)

        json = response.parsed_body
        expect(json.count).to eq(1)
        expect(json.first["id"]).to eq(published_event.id)
      end
    end

    context "when authenticated as basic user" do
      it "returns only published events" do
        get "/api/events", headers: user_headers
        json = response.parsed_body
        expect(json.count).to eq(1)
      end
    end

    context "when authenticated as an administrator" do
      it "returns all events including drafts" do
        get "/api/events", headers: admin_headers
        json = response.parsed_body
        expect(json.count).to eq(2)
      end
    end
  end

  describe "GET /api/events/:id" do
    context "when requesting a published event" do
      it "returns the event" do
        get "/api/events/#{published_event.id}"
        expect(response).to have_http_status(:success)
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
          published: false,
          bg_color_hex: "#7C3AED",
          data: { "location" => "Virtual / Worldwide", "format" => "DIGITAL" }
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

    it "allows administrators to create events" do
      expect do
        post "/api/events", params: valid_params, headers: admin_headers
      end.to change(Event, :count).by(1)
      expect(response).to have_http_status(:created)

      json = response.parsed_body
      expect(json["title"]).to eq("New Stream")
      expect(json["bg_color_hex"]).to eq("#7C3AED")
      expect(json["background_hex_color"]).to eq("#7C3AED")
      expect(json["location"]).to eq("Virtual / Worldwide")
      expect(json["format"]).to eq("DIGITAL")
      expect(json["social_image_url"]).to be_present
    end

    it "performs idempotent upsert when an event with matching slugs already exists" do
      existing = create(:event, event_name_slug: "sync-event", event_variation_slug: "2026", title: "Old Title")

      sync_params = {
        event: {
          title: "Updated Title via Sync",
          event_name_slug: "sync-event",
          event_variation_slug: "2026",
          start_time: 1.day.from_now,
          end_time: 2.days.from_now,
          bg_color_hex: "#0D9488"
        }
      }.to_json

      expect do
        post "/api/events", params: sync_params, headers: admin_headers
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:ok)
      expect(existing.reload.title).to eq("Updated Title via Sync")
      expect(existing.bg_color_hex).to eq("#0D9488")
    end
  end

  describe "PATCH /api/events/:id" do
    let!(:event) { create(:event, title: "Original Event", event_name_slug: "original-slug") }

    it "allows administrators to update an event by numeric id" do
      patch "/api/events/#{event.id}", params: { event: { title: "Updated by ID" } }.to_json, headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(event.reload.title).to eq("Updated by ID")
    end

    it "allows administrators to update an event by slug" do
      patch "/api/events/#{event.event_name_slug}", params: { event: { title: "Updated by Slug" } }.to_json,
                                                    headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(event.reload.title).to eq("Updated by Slug")
    end
  end

  describe "DELETE /api/events/:id" do
    let!(:event) { create(:event) }

    it "allows administrators to delete an event" do
      expect do
        delete "/api/events/#{event.id}", headers: admin_headers
      end.to change(Event, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
