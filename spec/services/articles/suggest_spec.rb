require "rails_helper"

RSpec.describe Articles::Suggest, type: :service do
  it "returns proper number of articles with post with the same tags", :flaky do
    create_list(:article, 4, featured: true, tags: ["discuss"], score: 10)
    article = create(:article, featured: true, tags: ["discuss"])
    expect(described_class.call(article).size).to eq(4)
  end

  it "returns proper number of articles with post with different tags", :flaky do
    create_list(:article, 2, featured: true, tags: ["discuss"], score: 10)
    create_list(:article, 2, featured: true, tags: ["javascript"])
    article = create(:article, featured: true, tags: ["discuss"])
    expect(described_class.call(article).size).to eq(4)
  end

  it "returns proper number of articles with post without tags", :flaky do
    # Flaky because sometime it returns 3 instead of 4
    create_list(:article, 5, tags: [], with_tags: false, featured: true)
    article = create(:article, featured: true, tag_list: "")
    expect(described_class.call(article).size).to eq(4)
  end

  it "returns the number of articles requested", :flaky do
    articles = create_list(:article, 3, featured: true)
    expect(described_class.call(articles.first).size).to eq(2)
  end
end
