# spec/requests/billboard_events_spec.rb
require "rails_helper"

RSpec.describe "BillboardEvents", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:billboard) { create(:billboard, name: "test") }

  before do
    # Stub out session_current_user_id and geolocation
    allow_any_instance_of(BillboardEventsController)
      .to receive(:session_current_user_id).and_return(user.id)
    allow_any_instance_of(BillboardEventsController)
      .to receive(:client_geolocation).and_return("test-geo")

    # Ensure Sidekiq is in fake mode and clear any existing jobs
    Sidekiq::Testing.fake!
    Billboards::DataUpdateWorker.clear
  end

  describe "POST /billboard_events" do
    let(:base_params) do
      {
        context_type: "home",
        category: "impression",
        billboard_id: billboard.id,
        article_id: article.id
      }
    end
  
    it "creates a BillboardEvent, enqueues the worker, and returns the ID as JSON" do
      expect {
        post billboard_events_path, params: { billboard_event: base_params }
      }.to change(BillboardEvent, :count).by(1)
        .and change(Billboards::DataUpdateWorker.jobs, :size).by(1)

      event = BillboardEvent.last
      expect(event.context_type).to eq("home")
      expect(event.category).to eq("impression")
      expect(event.billboard_id).to eq(billboard.id)
      expect(event.article_id).to eq(article.id)
      expect(event.user_id).to eq(user.id)

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(event.id)
    end

    context "when the request comes from an embedding site" do
      let(:embed_origin) { "https://embed.example.com" }

      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("BILLBOARD_EMBED_ORIGINS")
          .and_return("#{embed_origin}, https://other-embed.example.com")
      end

      it "records an anonymous embed event" do
        post bb_tabulations_path, params: { billboard_event: base_params }, headers: { "Origin" => embed_origin }

        event = BillboardEvent.last
        expect(event.context_type).to eq(BillboardEvent::CONTEXT_TYPE_EMBED)
        expect(event.user_id).to be_nil
      end

      it "allows the cross-origin preflight" do
        options bb_tabulations_path, headers: {
          "Origin" => embed_origin,
          "Access-Control-Request-Method" => "POST",
          "Access-Control-Request-Headers" => "content-type"
        }

        expect(response.headers["Access-Control-Allow-Origin"]).to eq(embed_origin)
      end

      it "does not allow other origins" do
        options bb_tabulations_path, headers: {
          "Origin" => "https://example.com",
          "Access-Control-Request-Method" => "POST"
        }

        expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
      end

      it "keeps the session user for other origins" do
        post bb_tabulations_path, params: { billboard_event: base_params }, headers: { "Origin" => "https://example.com" }

        expect(BillboardEvent.last).to have_attributes(user_id: user.id, context_type: "home")
      end
    end
  end

  describe "PATCH /bb_tabulations/:id" do
    context "when event exists and is an impression" do
      let!(:event) { create(:billboard_event, billboard: billboard, category: "impression", user: user, seconds_visible: 10) }

      it "updates seconds_visible by 10 without a preliminary find_by query if not updated recently" do
        event.update_column(:updated_at, 10.seconds.ago)
        allow(BillboardEvent).to receive(:find_by).and_call_original
        patch "/bb_tabulations/#{event.id}"
        expect([response.status, event.reload.seconds_visible]).to eq([200, 20])
        expect(BillboardEvent).not_to have_received(:find_by)
      end

      it "updates with a single SQL statement that keeps synchronous_commit off" do
        event.update_column(:updated_at, 10.seconds.ago)
        # Request-wide middleware (e.g. subforem lookups) also queries, so only count the event table.
        queries = []
        callback = lambda do |*, payload|
          queries << payload[:sql] if payload[:sql].include?(BillboardEvent.table_name)
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          patch "/bb_tabulations/#{event.id}"
        end

        expect(response).to have_http_status(:ok)
        expect(queries.size).to eq(1)
        expect(queries.first).to start_with("SET LOCAL synchronous_commit TO OFF; UPDATE")
        expect(event.reload.seconds_visible).to eq(20)
      end

      it "returns too_many_requests if updated too recently" do
        patch "/bb_tabulations/#{event.id}"
        expect(response.status).to eq(429)
        expect(event.reload.seconds_visible).to eq(10)
      end
    end

    context "when event category is not impression" do
      let!(:event) { create(:billboard_event, billboard: billboard, category: "click", user: user, seconds_visible: 10) }

      it "does not update seconds_visible" do
        event.update_column(:updated_at, 10.seconds.ago)
        patch "/bb_tabulations/#{event.id}"
        expect(response.status).to eq(200)
        expect(event.reload.seconds_visible).to eq(10)
      end
    end

    context "when event is for another user" do
      let(:other_user) { create(:user) }
      let!(:event) { create(:billboard_event, billboard: billboard, category: "impression", user: other_user, seconds_visible: 10) }

      it "returns forbidden status" do
        event.update_column(:updated_at, 10.seconds.ago)
        patch "/bb_tabulations/#{event.id}"
        expect(response.status).to eq(403)
        expect(event.reload.seconds_visible).to eq(10)
      end
    end

    context "when event does not exist" do
      it "returns not found status" do
        patch "/bb_tabulations/999999"
        expect(response.status).to eq(404)
      end

      it "returns not found status for a non-numeric id" do
        patch "/bb_tabulations/not-an-id"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
