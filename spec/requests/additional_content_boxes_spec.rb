require "rails_helper"

RSpec.describe "AdditionalContentBoxes", type: :request do
  let(:regular_article) { create(:article) }

  describe "GET /additional_content_boxes" do
    it "returns an article if there is a published/featured one" do
      suggestion = create(:article, published: true, featured: true)
      get "/additional_content_boxes?article_id=#{regular_article.id}"
      expect(response.body).to include CGI.escapeHTML(suggestion.title)
    end

    it "returns no article if not published/featured" do
      suggestion = create(:article)
      get "/additional_content_boxes?article_id=#{regular_article.id}"
      expect(response.body).not_to include CGI.escapeHTML(suggestion.title)
    end
  end
end
