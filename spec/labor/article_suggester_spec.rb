require "rails_helper"

RSpec.describe ArticleSuggester do
  let(:user) { create(:user) }

  it "returns proper number of articles with post with the same tags" do
    create_list(:article, 4, user: user, featured: true, tags: ["discuss"])
    article = create(:article, user: user, featured: true, tags: ["discuss"])
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns proper number of articles with post with different tags" do
    create_list(:article, 2, user: user, featured: true, tags: ["discuss"])
    create_list(:article, 2, user: user, featured: true, tags: ["javascript"])
    article = create(:article, user: user, featured: true, tags: ["discuss"])
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns proper number of articles with post without tags" do
    create_list(:article, 5, user: user, tags: [], with_tags: false, featured: true)
    article = create(:article, user: user, featured: true, tag_list: "")
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns the number of articles requested" do
    articles = create_list(:article, 3, user: user, featured: true)
    expect(described_class.new(articles.first).articles(max: 2).size).to eq(2)
  end
end
