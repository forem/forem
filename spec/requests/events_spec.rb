require "rails_helper"

RSpec.describe "Events", type: :request do
  before do
    @event = create(:event)
  end
  describe "GET events" do
    it "returns index page" do
      get "/events"
      expect(response.body).to include "DEV EVENTS"
    end

    it "returns event show page" do
      @event.published = true
      @event.save
      get "/events/#{@event.slug}"
      expect(response.body).to include @event.title
    end
  end
end