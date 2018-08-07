require "rails_helper"

RSpec.describe ArticleSuggester do
  let(:user) { create(:user) }

  before do
    create(:article, user_id: user.id, featured: true)
    create(:article, user_id: user.id, featured: true)
    create(:article, user_id: user.id, featured: true)
    create(:article, user_id: user.id, featured: true)
  end

  it "returns proper number of articles with post with tags" do
    article = create(:article, user_id: user.id, featured: true)
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns proper number of articles with post without tags" do
    article = create(:article, user_id: user.id, featured: true)
    article.tag_list = ""
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns proper number articles if number is passed" do
    expect(described_class.new(Article.last).articles(2).size).to eq(2)
  end
end
