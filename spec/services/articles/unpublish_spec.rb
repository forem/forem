require "rails_helper"

RSpec.describe Articles::Unpublish, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, published: true) }
  let(:frontmatter) { "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello" }
  let(:frontmatter_article) { create(:article, body_markdown: frontmatter) }

  before { article.update(body_markdown: Faker::Hipster.paragraph(sentence_count: 2)) }

  it "unpublishes article without frontmatter" do
    expect(article.has_frontmatter?).to be(false)
    expect do
      described_class.call(user, article)
    end.to change(article, :published?).from(true).to(false)
  end

  it "unpublishes article with frontmatter" do
    expect(frontmatter_article.has_frontmatter?).to be(true)
    expect do
      described_class.call(user, frontmatter_article)
    end.to change(frontmatter_article, :published?).from(true).to(false)
  end
end
