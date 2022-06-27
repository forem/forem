require "rails_helper"

RSpec.describe Articles::Unpublish, type: :service do
  let(:article) { create(:article, :published) }
  let(:frontmatter) { "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello" }
  let(:frontmatter_article) { create(:article, body_markdown: frontmatter) }

  before { article.update(body_markdown: Faker::Hipster.paragraph(sentence_count: 2)) }

  it "unpublishes article without frontmatter" do
    expect(article.has_frontmatter?).to be(false)
    expect do
      described_class.call(article)
    end.to change(:random_article, published?).from(true).to(false)
  end

  it "unpublishes article with frontmatter" do
    expect(frontmatter_article.has_frontmatter?).to be(true)
    expect do
      described_class.call(frontmatter_article)
    end.to change(:random_article, published?).from(true).to(false)
  end
end
