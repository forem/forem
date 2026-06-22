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
  end

  describe "PATCH /bb_tabulations/:id" do
    context "when event exists and is an impression" do
      let!(:event) { create(:billboard_event, billboard: billboard, category: "impression", user: user, seconds_visible: 10) }

      it "updates seconds_visible by 10" do
        patch "/bb_tabulations/#{event.id}"
        expect(response.status).to eq(200)
        expect(event.reload.seconds_visible).to eq(20)
      end
    end

    context "when event category is not impression" do
      let!(:event) { create(:billboard_event, billboard: billboard, category: "click", user: user, seconds_visible: 10) }

      it "does not update seconds_visible" do
        patch "/bb_tabulations/#{event.id}"
        expect(response.status).to eq(200)
        expect(event.reload.seconds_visible).to eq(10)
      end
    end

    context "when event is for another user" do
      let(:other_user) { create(:user) }
      let!(:event) { create(:billboard_event, billboard: billboard, category: "impression", user: other_user, seconds_visible: 10) }

      it "returns forbidden status" do
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
    end
  end
end
