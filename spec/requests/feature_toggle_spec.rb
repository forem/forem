require "rails_helper"

RSpec.describe "internal/features", type: :request do
  describe "GET /internal/features" do
    it "has proper headline" do
      user = create(:user)
      get "/internal/features"
      expect(response.body).to include("Practical Developer Features")
    end
  end
end
