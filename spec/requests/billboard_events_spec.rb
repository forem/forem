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
  
    it "creates a BillboardEvent and enqueues the worker" do
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
    end
  end
end
