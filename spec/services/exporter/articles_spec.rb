require "rails_helper"

RSpec.describe Exporter::Articles, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:other_user) { create(:user) }
  let(:other_user_article) { create(:article, user: other_user) }

  def valid_instance(user)
    described_class.new(user)
  end

  def expected_fields
    %w[
      body_markdown
      cached_tag_list
      cached_user_name
      cached_user_username
      canonical_url
      comments_count
      created_at
      crossposted_at
      description
      edited_at
      feed_source_url
      last_comment_at
      main_image
      main_image_background_hex_color
      path
      public_reactions_count
      processed_html
      published
      published_at
      published_from_feed
      show_comments
      slug
      social_image
      title
      video
      video_closed_caption_track_url
      video_code
      video_source_url
      video_thumbnail_url
    ]
  end

  def load_articles(data)
    JSON.parse(data["articles.json"])
  end

  describe "#initialize" do
    it "accepts a user" do
      exporter = valid_instance(user)
      expect(exporter.user).to be(user)
    end

    it "names itself articles" do
      exporter = valid_instance(user)
      expect(exporter.name).to eq(:articles)
    end
  end

  describe "#export" do
    context "when slug is unknown" do
      it "returns no articles if the slug is not found" do
        exporter = valid_instance(user)
        result = exporter.export(slug: "not found")
        articles = load_articles(result)
        expect(articles).to be_empty
      end

      it "no articles if slug belongs to another user" do
        exporter = valid_instance(user)
        result = exporter.export(slug: other_user_article.slug)
        articles = load_articles(result)
        expect(articles).to be_empty
      end
    end

    context "when slug is known" do
      it "returns the article" do
        exporter = valid_instance(user)
        result = exporter.export(slug: article.slug)
        articles = load_articles(result)
        expect(articles.length).to eq(1)
      end

      it "returns only expected fields for the article" do
        exporter = valid_instance(user)
        result = exporter.export(slug: article.slug)
        articles = load_articles(result)
        expect(articles.first.keys).to match_array(expected_fields)
      end
    end

    context "when all articles are requested" do
      it "returns all the articles as json" do
        exporter = valid_instance(article.user)
        result = exporter.export
        articles = load_articles(result)
        user.reload
        expect(articles.length).to eq(user.articles.size)
      end

      it "returns only expected fields for the article" do
        exporter = valid_instance(article.user)
        result = exporter.export
        articles = load_articles(result)
        expect(articles.first.keys).to match_array(expected_fields)
      end
    end
  end
end
