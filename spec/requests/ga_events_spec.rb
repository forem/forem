require "rails_helper"

vcr_option = {
  cassette_name: "ga_event",
  allow_playback_repeats: "true"
}

RSpec.describe "GaEvents", vcr: vcr_option do
  describe "POST /fallback_activity_recorder" do
    it "posts to fallback_activity_recorder" do
      post "/fallback_activity_recorder", params: {
        path: "/ben", user_language: "en"
      }.to_json
      expect(response.body).to eq("")
    end

    it "renders normal response even if the Forem instance is private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)
      post "/fallback_activity_recorder", params: {
        path: "/ben", user_language: "en"
      }.to_json
      expect(response.body).to eq("")
    end

    context "when GA4 is configured" do
      let(:tracking_service) { instance_double(Ga::TrackingService, track_event: nil) }

      before do
        allow(Settings::General).to receive_messages(ga_analytics_4_id: "G-TEST", ga_api_secret: "secret")
        allow(Ga::TrackingService).to receive(:new).and_return(tracking_service)
      end

      it "rejects a truncated JSON body without enqueuing a page_view", :aggregate_failures do
        sidekiq_assert_no_enqueued_jobs(only: Ga::TrackEventWorker) do
          post "/fallback_activity_recorder", params: '{"path":"/example","document_path":"/example'
        end

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq("")
        expect(response.cookies["client_id"]).to be_nil
      end

      it "rejects malformed JSON with JSON headers without enqueuing a page_view", :aggregate_failures do
        sidekiq_assert_no_enqueued_jobs(only: Ga::TrackEventWorker) do
          post "/fallback_activity_recorder",
               params: '{"path":"/example","document_path":"/example',
               headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
        end

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq("")
        expect(response.cookies["client_id"]).to be_nil
      end

      it "rejects an empty body without enqueuing a page_view", :aggregate_failures do
        sidekiq_assert_no_enqueued_jobs(only: Ga::TrackEventWorker) do
          post "/fallback_activity_recorder", params: ""
        end

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq("")
        expect(response.cookies["client_id"]).to be_nil
      end

      it "sends the page_view from a job instead of during the request", :aggregate_failures do
        sidekiq_assert_enqueued_jobs(1, only: Ga::TrackEventWorker) do
          post "/fallback_activity_recorder", params: { path: "/example", user_language: "en" }.to_json
        end

        expect(response.body).to eq("")
        expect(response.cookies["client_id"]).to be_present
        expect(Ga::TrackingService).not_to have_received(:new)
      end

      it "sends the same page_view payload to Google Analytics", :aggregate_failures do
        sidekiq_perform_enqueued_jobs do
          post "/fallback_activity_recorder", params: {
            document_title: "Example", path: "/example", user_language: "en", referrer: "https://example.com/"
          }.to_json
        end

        expect(Ga::TrackingService).to have_received(:new).with("G-TEST", "secret", kind_of(String))
        expected_params = {
          page_title: "Example", page_location: nil, page_path: "/example", user_id: nil,
          user_language: "en", referrer: "https://example.com/", user_agent: nil, viewport_size: nil,
          screen_resolution: nil, document_encoding: nil, data_source: "web"
        }.stringify_keys
        expect(tracking_service).to have_received(:track_event).with("page_view", expected_params)
      end

      it "extracts signed-in user_id from session and skips session commit without loading User", :aggregate_failures do
        user = create(:user)
        sign_in user
        allow(User).to receive(:find_by).and_call_original

        sidekiq_perform_enqueued_jobs do
          post "/fallback_activity_recorder", params: {
            document_title: "Feed", path: "/", user_language: "en", referrer: URL.url("/internal")
          }.to_json
        end

        expect(response).to have_http_status(:ok)
        expect(request.session_options[:skip]).to be(true)
        expect(User).not_to have_received(:find_by)
        expected_params = {
          page_title: "Feed", page_location: nil, page_path: "/", user_id: user.id,
          user_language: "en", referrer: nil, user_agent: nil, viewport_size: nil,
          screen_resolution: nil, document_encoding: nil, data_source: "web"
        }.stringify_keys
        expect(tracking_service).to have_received(:track_event).with("page_view", expected_params)
      end
    end
  end
end
