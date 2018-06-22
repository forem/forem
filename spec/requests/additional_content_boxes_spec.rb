require "rails_helper"

RSpec.describe "AdditionalContentBoxes", type: :request do
  describe "GET /additional_content_boxes" do
    it "returns an article if there is a published/featured one" do
      suggestion = create(:article, published: true, featured: true)
      suggestion.update_column(:published, true)
      article = create(:article)
      get "/additional_content_boxes?article_id=#{article.id}"
      expect(response.body).to include(suggestion.title)
    end
    it "returns no article if not published/featured" do
      suggestion = create(:article)
      article = create(:article)
      get "/additional_content_boxes?article_id=#{article.id}"
      expect(response.body).to_not include(suggestion.title)
    end
  end
end