require "rails_helper"
require "zip"

RSpec.describe Exporter::Service do
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

  def extract_zipped_exports(buffer)
    exports = {}

    buffer.rewind
    Zip::InputStream.open(buffer) do |stream|
      loop do
        entry = stream.get_next_entry
        break if entry.blank?
        exports[entry.name] = stream.read
      end
    end

    exports
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

  describe "EXPORTERS" do
    it "is a list of supported exporters" do
      expect(described_class::EXPORTERS).to eq([Exporter::Articles])
    end
  end

  describe "#initialize" do
    it "accepts a user" do
      service = valid_instance(user)
      expect(service.user).to be(user)
    end
  end

  describe "#export" do
    it "exports a zip file with files" do
      service = valid_instance(article.user)
      zipped_exports = service.export
      exports = extract_zipped_exports(zipped_exports)
      expect(exports.keys).to eq(["articles.json"])
    end

    it "passes configuration to an exporter" do
      service = valid_instance(article.user)
      zipped_exports = service.export(config: { articles: { slug: article.slug } })
      exports = extract_zipped_exports(zipped_exports)
      expect(exports.length).to eq(1)
    end

    context "when emailing the user" do
      it "delivers one email" do
        service = valid_instance(article.user)
        service.export(send_email: true)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it "delivers an email with the export" do
        service = valid_instance(article.user)
        zipped_export = service.export(send_email: true)
        attachment = ActionMailer::Base.deliveries.last.attachments[0].decoded

        exports = extract_zipped_exports(zipped_export)
        expect(exports).to eq(extract_zipped_exports(StringIO.new(attachment)))
      end
    end

    it "sets the requested flag as false" do
      service = valid_instance(article.user)
      service.export
      expect(user.export_requested).to be(false)
    end

    it "sets the exported at datetime as the current one" do
      Timecop.freeze(Time.current) do
        service = valid_instance(article.user)
        service.export
        expect(user.exported_at).to eq(Time.current)
      end
    end
  end
end
