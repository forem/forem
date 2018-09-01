require "rails_helper"
require "zip"

RSpec.describe ArticleExportService do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:other_user) { create(:user) }
  let(:other_user_article) { create(:article, user: other_user) }

  before do
    ActionMailer::Base.deliveries.clear
  end

  def valid_instance(user)
    described_class.new(user)
  end

  def extract_zipped_articles(buffer)
    output = ""
    buffer.rewind
    Zip::InputStream.open(buffer) do |stream|
      loop do
        entry = stream.get_next_entry
        break if entry.blank?
        continue unless entry.name == "articles.json"
        output = stream.read
      end
    end
    JSON.parse(output)
  end

  def expected_fields
    [
      "body_html",
      "body_markdown",
      "cached_tag_list",
      "cached_user_name",
      "cached_user_username",
      "canonical_url",
      "comments_count",
      "created_at",
      "crossposted_at",
      "description",
      "edited_at",
      "feed_source_url",
      "language",
      "last_comment_at",
      "lat",
      "long",
      "main_image",
      "main_image_background_hex_color",
      "path",
      "positive_reactions_count",
      "processed_html",
      "published",
      "published_at",
      "published_from_feed",
      "reactions_count",
      "show_comments",
      "slug",
      "social_image",
      "title",
      "updated_at",
      "video",
      "video_closed_caption_track_url",
      "video_code",
      "video_source_url",
      "video_thumbnail_url",
    ]
  end

  describe "#initialize" do
    it "accepts a user" do
      service = valid_instance(user)
      expect(service.user).to be(user)
    end
  end

  describe "#export" do
    context "when slug is unknown" do
      it "returns stream with no articles if the slug is not found" do
        service = valid_instance(user)
        zipped_export = service.export(slug: "not found")
        articles = extract_zipped_articles(zipped_export)
        expect(articles).to be_empty
      end

      it "returns stream with no articles if slug belongs to another user" do
        service = valid_instance(user)
        zipped_export = service.export(slug: other_user_article.slug)
        articles = extract_zipped_articles(zipped_export)
        expect(articles).to be_empty
      end
    end

    context "when slug is known" do
      it "returns a stream with the article" do
        service = valid_instance(user)
        zipped_export = service.export(slug: article.slug)
        articles = extract_zipped_articles(zipped_export)
        expect(articles.length).to eq(1)
      end

      it "returns only expected fields for the article" do
        service = valid_instance(user)
        zipped_export = service.export(slug: article.slug)
        articles = extract_zipped_articles(zipped_export)
        expect(articles.first.keys).to eq(expected_fields)
      end
    end

    context "when all articles are requested" do
      it "returns a stream with all the articles as json" do
        service = valid_instance(article.user)
        zipped_export = service.export
        articles = extract_zipped_articles(zipped_export)
        expect(articles.length).to eq(user.articles.size)
      end

      it "returns only expected fields for articles" do
        service = valid_instance(article.user)
        zipped_export = service.export
        articles = extract_zipped_articles(zipped_export)
        expect(articles.first.keys).to eq(expected_fields)
      end
    end

    context "with the user notification" do
      it "delivers one email" do
        service = valid_instance(article.user)
        service.export(notify_user: true)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it "delivers an email with the export" do
        service = valid_instance(article.user)
        zipped_export = service.export(notify_user: true)
        attachment = ActionMailer::Base.deliveries.last.attachments[0].decoded

        expected_articles = extract_zipped_articles(zipped_export)
        expect(expected_articles).to eq(extract_zipped_articles(StringIO.new(attachment)))
      end
    end

    it "sets the requested flag as false" do
      service = valid_instance(article.user)
      service.export
      expect(user.articles_export_requested).to be(false)
    end

    it "sets the exported at datetime as the current one" do
      Timecop.freeze(Time.current) do
        service = valid_instance(article.user)
        service.export
        expect(user.articles_exported_at).to eq(Time.current)
      end
    end
  end
end
