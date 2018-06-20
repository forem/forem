require "rails_helper"

RSpec.describe "Live Articles", type: :request do
  describe "GET /live_articles" do
    it "returns no articles if none are live" do
      get "/live_articles"
      expect(response.body).to eq("{}")
    end

    it "returns a live article if it is live" do
      article = create(:article, live_now: true)
      get "/live_articles"
      expect(response.body).to include(article.title)
    end
    it "returns a live event if it is live" do
      event = create(:event, live_now: true)
      get "/live_articles"
      expect(response.body).to include(event.title)
    end
  end
end
