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

      context "when the event has associated articles via tags" do
        let(:tag) { create(:tag, name: "awstest") }
        let(:article) { create(:article, title: "A Custom Event Article", cached_tag_list: tag.name) }

        before do
          published_event.tags << tag
          article # force article creation in DB so it can be queried
        end

        it "renders the articles with their tags successfully without throwing NoMethodError" do
          get event_path(published_event.event_name_slug, published_event.event_variation_slug)
          
          expect(response).to have_http_status(:success)
          expect(response.body).to include("A Custom Event Article")
          expect(response.body).to include(article.path)
          expect(response.body).to include("##{tag.name}")
        end
      end
    end

    context "when requesting a draft event" do
      context "as a logged out user" do
        it "raises a 404 RoutingError as if it does not exist" do
          expect {
            get event_path(draft_event.event_name_slug, draft_event.event_variation_slug)
          }.to raise_error(ActionController::RoutingError, "Not Found")
        end
      end

      context "as a regular logged in user" do
        let(:regular_user) { create(:user) }
        
        before { login_as(regular_user) }

        it "raises a 404 RoutingError to maintain draft secrecy" do
          expect {
            get event_path(draft_event.event_name_slug, draft_event.event_variation_slug)
          }.to raise_error(ActionController::RoutingError, "Not Found")
        end
      end

      context "as an admin" do
        let(:admin) { create(:user, :super_admin) }
        
        before { login_as(admin) }

        it "renders the show view with an unpublished warning banner" do
          get event_path(draft_event.event_name_slug, draft_event.event_variation_slug)
          
          expect(response).to have_http_status(:success)
          expect(response.body).to include("This event is not published!")
          expect(response.body).to include("Edit Event")
        end
      end
    end
    
    context "when an event does not exist" do
      context "and a matching page does not exist" do
        it "raises an ActiveRecord::RecordNotFound implicitly handled as a 404" do
          expect {
            get "/events/does-not-exist/version"
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "and a matching page exists" do
        let!(:fallback_page) { create(:page, slug: "events/midnight/april-2-2026", body_markdown: "This is the fallback midnight event page") }
        
        it "renders the page instead of raising a 404" do
          get "/events/midnight/april-2-2026"
          
          expect(response).to have_http_status(:success)
          expect(response.body).to include("This is the fallback midnight event page")
        end
      end
    end
  end
end
