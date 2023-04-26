require "rails_helper"

RSpec.describe Articles::ApiSearchQuery, type: :query do
  before do
    create(:article, published: false)
    create(:article, title: "Top ten Interview tips")
    create(:article, title: "Top ten Ruby tips")
    create(:article, title: "Frontend Frameworks", published_at: 2.days.from_now)
    create(:article)
  end

  context "when there is no query parameter" do
    it "shows all published and approved articles" do
      articles = described_class.call({})
      expect(articles.count).to eq(4)
    end
  end

  context "when there is a query parameter" do
    it "shows articles that match that query" do
      articles = described_class.call({ q: "ruby" })
      expect(articles.count).to eq(1)
    end
  end

  context "when there is a top parameter" do
    it "shows the most popular articles in the last n days" do
      articles = described_class.call({ top: 10 })
      expect(articles.count).to eq(3)
    end
  end
end
