require "rails_helper"

RSpec.describe "ReactionsGet", type: :request do
  describe "GET podcast episodes index" do
    it "returns reaction counts for article" do
      article = create(:article)
      get "/reactions/logged_out_reaction_counts?article_id=#{article.id}"
      expect(response.body).to include("article_reaction_counts")
    end
    it "renders page with proper sidebar" do
      article = create(:article)
      comment = create(:comment, commentable_id: article.id)
      
      get "/reactions/logged_out_reaction_counts?commentable_id=#{article.id}&commentable_type=Comment"
      expect(response.body).to include("positive_reaction_counts")
    end
  end
end
