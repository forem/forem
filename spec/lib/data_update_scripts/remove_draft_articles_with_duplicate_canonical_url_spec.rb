require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200901085230_remove_draft_articles_with_duplicate_canonical_url.rb")

describe DataUpdateScripts::RemoveDraftArticlesWithDuplicateCanonicalUrl do
  it "removes draft articles that have the same canonical url and the same body keeping the first" do
    articles = create_list(:article, 3, published: false)

    # we bypass the callbacks intentionally as canonical url has a unique callback at the Rails level
    articles.each do |article|
      article.update_columns(
        body_markdown: "body",
        canonical_url: "https://example.com/article",
      )
    end

    number_of_articles_to_remove = articles.size - 1

    expect { described_class.new.run }.to change(Article, :count).by(-number_of_articles_to_remove)

    articles.sort_by!(&:id)

    expect(Article.exists?(articles.first.id)).to be(true)
    expect(Article.exists?(articles.second.id)).to be(false)
    expect(Article.exists?(articles.third.id)).to be(false)
  end

  it "removes draft articles that have the same canonical url and different bodies keeping the most recent" do
    articles = create_list(:article, 3, published: false)

    # we bypass the callbacks intentionally as canonical url has a unique callback at the Rails level
    articles.each do |article|
      article.update_columns(
        created_at: Faker::Time.between(from: Time.current, to: 2.days.ago),
        canonical_url: "https://example.com/article",
      )
    end

    number_of_articles_to_remove = articles.size - 1

    expect { described_class.new.run }.to change(Article, :count).by(-number_of_articles_to_remove)

    articles.sort_by! { |a| -a.created_at.to_i }

    expect(Article.exists?(articles.first.id)).to be(true)
    expect(Article.exists?(articles.second.id)).to be(false)
    expect(Article.exists?(articles.third.id)).to be(false)
  end
end
