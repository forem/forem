require "rails_helper"

RSpec.describe CacheBuster do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }

  it "busts comment" do
    commentable = Article.find(comment.commentable_id)
    username = User.find(comment.user_id).username
    described_class.new.bust_comment(commentable, username)
  end
  it "busts article" do
    described_class.new.bust_article(article)
  end
  it "busts featured article" do
    article.featured = true
    article.save
    described_class.new.bust_article(article)
  end
end
