# spec/requests/billboards_spec.rb
require "sidekiq/testing"

RSpec.describe "BillboardEvents", type: :request do
  before do
    # Ensure Sidekiq is in fake mode so we can inspect the enqueued jobs
    Sidekiq::Testing.fake!
  end

  let(:user)      { create(:user) }
  let(:billboard) { create(:billboard, approved: true, published: true) }

  context "POST /billboard_events" do
    let(:valid_params) do
      {
        billboard_event: {
          billboard_id: billboard.id,
          category:     "impression",
          context_type: "sidebar",
          geolocation:  "US-CA"
        }
      }
    end

    before do
      sign_in user
    end

    it "creates a BillboardEvent and enqueues DataUpdateWorker" do
      # Clear any existing jobs
      Billboards::DataUpdateWorker.clear

      expect {
        post "/billboard_events", params: valid_params
      }.to change(BillboardEvent, :count).by(1)
         .and change(Billboards::DataUpdateWorker.jobs, :size).by(1)

      # Confirm that the enqueued job arguments include the billboard id
      job          = Billboards::DataUpdateWorker.jobs.last
      job_args     = job["args"]
      expect(job_args).to include(billboard.id)

      # Because we did not pass forced: true, second argument should be "false"
      expect(job_args).to include(false)
      expect(response).to have_http_status(:ok)
    end

    it "does not enqueue when DISABLE_BILLBOARD_DATA_UPDATE = 'yes'" do
      stub_const("ApplicationConfig", ApplicationConfig.merge("DISABLE_BILLBOARD_DATA_UPDATE" => "yes"))
      Billboards::DataUpdateWorker.clear

      expect {
        post "/billboard_events", params: valid_params
      }.to change(BillboardEvent, :count).by(1)
         .and change(Billboards::DataUpdateWorker.jobs, :size).by(0)

      expect(response).to have_http_status(:ok)
    end
  end
end
