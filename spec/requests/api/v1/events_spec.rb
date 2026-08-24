require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let!(:admin) { create(:user).tap { |u| u.add_role(:super_admin) } }
  let!(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:admin_headers) do
    {
      "api-key" => admin_api_secret.secret,
      "content-type" => "application/json",
      "Accept" => "application/vnd.forem.api-v1+json"
    }
  end

  let!(:user) { create(:user) }
  let!(:user_api_secret) { create(:api_secret, user: user) }
  let!(:user_headers) do
    {
      "api-key" => user_api_secret.secret,
      "content-type" => "application/json",
      "Accept" => "application/vnd.forem.api-v1+json"
    }
  end

  let!(:published_event) { create(:event, published: true, bg_color_hex: "#3B49DF", elevated: true) }
  let!(:draft_event) { create(:event, published: false) }

  describe "GET /api/events" do
    it "returns published events for public requests" do
      get "/api/events", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
      expect(json.first["id"]).to eq(published_event.id)
      expect(json.first["bg_color_hex"]).to eq("#3B49DF")
      expect(json.first["elevated"]).to be(true)
    end

    it "returns all events for super admins" do
      get "/api/events", headers: admin_headers
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json.count).to eq(2)
    end
  end

  describe "POST /api/events" do
    let(:valid_params) do
      {
        event: {
          title: "V1 Live Stream",
          event_name_slug: "v1-stream",
          event_variation_slug: "episode-1",
          start_time: 1.day.from_now,
          end_time: 2.days.from_now,
          type_of: "live_stream",
          primary_stream_url: "https://twitch.tv/ThePracticalDev",
          bg_color_hex: "#DB2777",
          elevated: true,
          published: true,
          tag_list: "ruby, rails"
        }
      }.to_json
    end

    it "creates an event with full visual styling" do
      expect {
        post "/api/events", params: valid_params, headers: admin_headers
      }.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("V1 Live Stream")
      expect(json["bg_color_hex"]).to eq("#DB2777")
      expect(json["elevated"]).to be(true)
      expect(json["social_image_url"]).to be_present
    end
  end

  describe "PUT /api/events/:id" do
    it "updates event properties" do
      put "/api/events/#{published_event.id}",
          params: { event: { title: "Updated V1 Title", elevated: false } }.to_json,
          headers: admin_headers

      expect(response).to have_http_status(:success)
      expect(published_event.reload.title).to eq("Updated V1 Title")
      expect(published_event.elevated).to be(false)
    end
  end

  describe "DELETE /api/events/:id" do
    it "deletes an event" do
      expect {
        delete "/api/events/#{draft_event.id}", headers: admin_headers
      }.to change(Event, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
