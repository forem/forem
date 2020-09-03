require "rails_helper"

RSpec.describe ArticleSuggester, type: :labor do
  it "returns proper number of articles with post with the same tags" do
    create_list(:article, 4, featured: true, tags: ["discuss"], score: 10)
    article = create(:article, featured: true, tags: ["discuss"])
    stub_estimated_article_count
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns proper number of articles with post with different tags" do
    create_list(:article, 2, featured: true, tags: ["discuss"], score: 10)
    create_list(:article, 2, featured: true, tags: ["javascript"])
    article = create(:article, featured: true, tags: ["discuss"])
    stub_estimated_article_count
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns proper number of articles with post without tags" do
    create_list(:article, 5, tags: [], with_tags: false, featured: true)
    article = create(:article, featured: true, tag_list: "")
    stub_estimated_article_count
    expect(described_class.new(article).articles.size).to eq(4)
  end

  it "returns the number of articles requested" do
    articles = create_list(:article, 3, featured: true)
    stub_estimated_article_count
    expect(described_class.new(articles.first).articles(max: 2).size).to eq(2)
  end

  def stub_estimated_article_count
    allow(described_class).to receive(:articles_count).and_return(Article.published.count)
  end
end
