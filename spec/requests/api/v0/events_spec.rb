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

    context "when filtering by type_of" do
      let!(:challenge_event) { create(:event, published: true, type_of: :challenge) }
      let!(:draft_challenge_event) { create(:event, published: false, type_of: :challenge) }
      let!(:stream_event) { create(:event, published: true, type_of: :live_stream) }

      it "returns only events matching the requested type_of when unauthenticated" do
        get "/api/events", params: { type_of: "challenge" }
        expect(response).to have_http_status(:success)

        json = response.parsed_body
        expect(json.pluck("id")).to contain_exactly(challenge_event.id)
      end

      it "returns only events matching the requested type_of for basic users" do
        get "/api/events", params: { type_of: "live_stream" }, headers: user_headers
        expect(response).to have_http_status(:success)

        json = response.parsed_body
        expect(json.pluck("id")).to include(stream_event.id)
        expect(json.pluck("id")).not_to include(challenge_event.id)
      end

      it "returns matching events including drafts for administrators" do
        get "/api/events", params: { type_of: "challenge" }, headers: admin_headers
        expect(response).to have_http_status(:success)

        json = response.parsed_body
        expect(json.pluck("id")).to contain_exactly(challenge_event.id, draft_challenge_event.id)
      end

      it "ignores invalid type_of values" do
        get "/api/events", params: { type_of: "nonexistent_type" }
        expect(response).to have_http_status(:success)

        json = response.parsed_body
        expect(json.pluck("id")).to include(published_event.id, challenge_event.id, stream_event.id)
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

    it "allows administrators to create events" do
      expect do
        post "/api/events", params: valid_params, headers: admin_headers
      end.to change(Event, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end
end
