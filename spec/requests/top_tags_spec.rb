require "rails_helper"

RSpec.describe "ArticlesApi", type: :request do
  describe "GET /tags" do
    it "returns proper page" do
      get "/tags"
      expect(response.body).to include("Top 100 Tags")
    end
  end
end
