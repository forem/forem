require "rails_helper"

RSpec.describe "ArticlesFeed" do
  let!(:article) { create(:article) }

  it "returns an rss feed with published articles" do
    get "/feed"

    expect(response.body).to include(article.title)
    expect(response.body).to include("<pubDate>#{article.published_at.to_fs(:rfc822)}</pubDate>")
  end
end
