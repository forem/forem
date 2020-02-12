require "rails_helper"

RSpec.describe "Events", type: :request do
  let_it_be(:event) { create(:event, published: true) }

  describe "GET events" do
    it "returns index page" do
      get "/events"
      expect(response.body).to include("DEV EVENTS")
      expect(response.body).to include(event.title)
    end

    it "does not include unpublished events" do
      unpublished_event = create(:event, published: false)
      get "/events"
      expect(response.body).not_to include(unpublished_event.title)
    end
  end

  describe "GET events#show" do
    it "returns event show page" do
      get "/events/#{event.slug}"
      expect(response.body).to include event.title
    end

    it "renders not_found" do
      expect do
        get "/events/NotSlug-#{event.slug}"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
