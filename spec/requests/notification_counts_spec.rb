require "rails_helper"

RSpec.describe "NotificationCounts", type: :request do
  describe "GET /notifications/counts" do
    it "returns a number" do
      # stubbed to be 1
      get "/notifications/counts"
      expect(response.body).to eq("1")
    end
  end
end
