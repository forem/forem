require "rails_helper"

RSpec.describe "Events", type: :request do
  before do
    @event = create(:event)
  end
  describe "GET /events" do
    it "returns proper page" do
      get "/events"
      expect(response.body).to include "DEV EVENTS"
    end
  end
end