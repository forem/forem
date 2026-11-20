require "rails_helper"

RSpec.describe "articles/_actions.html.erb" do
  let(:article) { create(:article) }

  let(:decorated_article) { article.decorate }

  before { assign(:article, decorated_article) }

  shared_examples "article share links" do
    it "builds the URL once and preserves every share destination" do
      allow(view).to receive(:article_url).with(decorated_article).and_return(share_url)

      render partial: "articles/actions"

      expect(view).to have_received(:article_url).with(decorated_article).once
      html = Nokogiri::HTML.fragment(rendered)
      expect(html.at_css("#copy-post-url-button")["data-posturl"]).to eq(share_url)
      expect(html.at_css("web-share-wrapper")["shareurl"]).to eq(share_url)
      links = html.css(".Desktop-only a").map { |link| Addressable::URI.parse(link["href"]).query_values }
      expect(links[0]["text"]).to end_with(" #{share_url}")
      expect(links[1]["url"]).to eq(share_url)
      expect(links[2]["u"]).to eq(share_url)
      expect(links[3]["text"]).to eq(share_url)
    end
  end

  context "with a regular article URL" do
    let(:share_url) { "https://example.com/author/synthetic-article" }

    include_examples "article share links"
  end

  context "with a custom domain and characters requiring escaping" do
    let(:share_url) { 'https://community.example.com/synthetic-article?first=1&second="quoted"' }

    include_examples "article share links"
  end

  context "when the article is unpublished" do
    let(:article) { create(:article, published: false) }

    it "does not build a share URL or render share controls" do
      allow(view).to receive(:article_url)

      render partial: "articles/actions"

      expect(view).not_to have_received(:article_url)
      expect(rendered).not_to include("copy-post-url-button", "web-share-wrapper")
    end
  end
end
