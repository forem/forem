require "rails_helper"

RSpec.describe "PollVotes", type: :request do
  describe "GET /pro" do
    it "returns pro lander" do
      get "/pro"
      expect(response.body).to include("Like a Pro")
    end
  end
end
