require "rails_helper"

RSpec.describe "Insights", type: :request do
  let(:user) { create(:user) }
  let(:algolia_service_instance) { instance_double(AlgoliaInsightsService) }

  before do
    allow(AlgoliaInsightsService).to receive(:new).and_return(algolia_service_instance)
    allow(algolia_service_instance).to receive(:track_event)
  end

  describe "POST /insights" do
    let(:valid_params) do
      {
        insight: {
          event_type: "click",
          event_name: "Result Clicked",
          object_id: "12345",
          index_name: "Article_production",
          query_id: "abcdef123456",
        }
      }
    end

    context "when user is signed in" do
      before { sign_in user }

      it "processes the insight and tracks the event", :aggregate_failures do
        post "/insights", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Insight processed")
        expect(algolia_service_instance).to have_received(:track_event).with(
          "click",
          "Result Clicked",
          user.id.to_s, # Coerced to string
          "12345",
          "Article_production",
          Time.current.to_i * 1000, # Converted to integer
          "abcdef123456"
        )
      end
    end

    context "when user is not signed in" do
      it "processes the insight without a user ID", :aggregate_failures do
        post "/insights", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Insight processed")
        expect(algolia_service_instance).to have_received(:track_event).with(
          "click",
          "Result Clicked",
          nil, # No user ID
          "12345",
          "Article_production",
          Time.current.to_i * 1000, # Converted to integer
          "abcdef123456"
        )
      end
    end

    context "when required parameters are missing" do
      let(:invalid_params) { { insight: { event_type: "click" } } }
    
      it "returns an error", :aggregate_failures do
        post "/insights", params: invalid_params
    
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Missing required parameters: event_name, object_id, index_name")
        expect(algolia_service_instance).not_to have_received(:track_event)
      end
    end
  end
end
