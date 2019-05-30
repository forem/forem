require "rails_helper"

RSpec.describe CacheBuster do
  let(:cache_buster) { described_class.new }
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }

  describe "#bust_comment" do
    it "busts comment" do
      cache_buster.bust_comment(comment.commentable, user.username)
    end

    it "works if commentable is missing" do
      cache_buster.bust_comment(nil, user.username)
    end

    it "works if username is missing" do
      cache_buster.bust_comment(comment.commentable, "")
    end
  end

  describe "#bust_article" do
    it "busts article" do
      cache_buster.bust_article(article)
    end

    it "busts featured article" do
      article.update_columns(featured: true)
      cache_buster.bust_article(article)
    end
  end
end
