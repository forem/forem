require "rails_helper"

RSpec.describe Articles::Suggest, type: :service do
  # Fix flaky tests by stubbing random offset to make results deterministic
  before do
    allow_any_instance_of(described_class).to receive(:offset).and_return(0)
  end

  it "returns proper number of articles with post with the same tags" do
    create_list(:article, 4, featured: true, tags: ["discuss"], score: 10)
    article = create(:article, featured: true, tags: ["discuss"])
    expect(described_class.call(article).size).to eq(4)
  end

  it "returns proper number of articles with post with different tags" do
    create_list(:article, 2, featured: true, tags: ["discuss"], score: 10)
    create_list(:article, 2, featured: true, tags: ["javascript"], score: 10)
    article = create(:article, featured: true, tags: ["discuss"], score: 10)
    expect(described_class.call(article).size).to eq(4)
  end

  it "returns proper number of articles with post without tags" do
    # Fixed: stub random offset to prevent flakiness
    create_list(:article, 5, tags: [], with_tags: false, featured: true, score: 10)
    article = create(:article, featured: true, tag_list: "")
    expect(described_class.call(article).size).to eq(4)
  end

  it "returns the number of articles requested" do
    articles = create_list(:article, 3, featured: true, score: 8)
    expect(described_class.call(articles.first).size).to eq(2)
  end
end
