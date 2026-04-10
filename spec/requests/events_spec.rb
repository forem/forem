require "rails_helper"

RSpec.describe "Events", type: :request do
  let!(:published_event) { create(:event, title: "Super Cool Launch Event", published: true) }
  let!(:draft_event)     { create(:event, title: "Secret Internal Test", published: false) }

  describe "GET /events" do
    it "renders the index successfully, displaying only published events" do
      get events_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include(published_event.title)
      expect(response.body).not_to include(draft_event.title)
    end
  end

  describe "GET /events/:id" do
    context "when requesting a published event" do
      it "renders the show view successfully" do
        # `event_path` natively uses the overloaded `to_param` (slug) we built!
        get event_path(published_event.event_name_slug, published_event.event_variation_slug)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include(published_event.title)
      end
    end

    context "when requesting a draft event" do
      it "raises a 404 RoutingError as if it does not exist" do
        expect {
          get event_path(draft_event.event_name_slug, draft_event.event_variation_slug)
        }.to raise_error(ActionController::RoutingError, "Not Found")
      end
    end
    
    context "when an event does not exist" do
      it "raises an ActiveRecord::RecordNotFound implicitly handled as a 404" do
        expect {
          get "/events/does-not-exist/version"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
