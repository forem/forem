require "rails_helper"

RSpec.describe CacheBuster do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }

  it "busts comment" do
    described_class.new.bust_comment(comment)
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
