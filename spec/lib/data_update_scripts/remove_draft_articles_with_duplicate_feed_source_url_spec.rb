require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20200904132553_remove_draft_articles_with_duplicate_feed_source_url.rb",
)

describe DataUpdateScripts::RemoveDraftArticlesWithDuplicateFeedSourceUrl do
  it "removes draft articles that have the same feed source url and the same body keeping the first" do
    articles = create_list(:article, 3, published: false)

    # we bypass the callbacks intentionally as feed source url has a unique callback at the Rails level
    articles.each do |article|
      article.update_columns(
        body_markdown: "body",
        feed_source_url: "https://example.com/article",
      )
    end

    number_of_articles_to_remove = articles.size - 1

    expect { described_class.new.run }.to change(Article, :count).by(-number_of_articles_to_remove)

    articles.sort_by!(&:id)

    expect(Article.exists?(articles.first.id)).to be(true)
    expect(Article.exists?(articles.second.id)).to be(false)
    expect(Article.exists?(articles.third.id)).to be(false)
  end

  it "removes draft articles that have the same feed source url and different bodies keeping the most recent" do
    articles = create_list(:article, 3, published: false)

    # we bypass the callbacks intentionally as feed source url has a unique callback at the Rails level
    articles.each do |article|
      article.update_columns(
        created_at: Faker::Time.between(from: Time.current, to: 2.days.ago),
        feed_source_url: "https://example.com/article",
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
