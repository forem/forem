require "rails_helper"

describe ArticlesHelper do
  describe ".get_host_without_www" do
    it "drops the www off of a valid url" do
      host = helper.get_host_without_www("https://www.example.com")
      expect(host).to eq "example.com"
    end

    it "lowercases the host name in general" do
      host = helper.get_host_without_www("https://www.EXAMPLE.COM")
      expect(host).to eq "example.com"
    end

    it "titlecases the host for medium.com and drops .com" do
      host = helper.get_host_without_www("https://www.medium.com")
      expect(host).to eq "Medium"
    end

    it "does not brand unrelated hosts that merely contain 'medium.com'" do
      host = helper.get_host_without_www("https://premedium.com")
      expect(host).to eq "premedium.com"
    end

    it "can handle urls without schemes" do
      host = helper.get_host_without_www("www.example.com")
      expect(host).to eq "example.com"
    end

    it "can handle URLs with leading and trailing whitespace" do
      host = helper.get_host_without_www(" www.example.com ")
      expect(host).to eq "example.com"
    end
  end

  describe "#image_tag_or_inline_svg_tag" do
    helper do
      def internal_navigation?
        true
      end
    end
    subject { helper.image_tag_or_inline_svg_tag("twitter") }

    it { is_expected.to start_with("<img") }

    context "with a width and height" do
      subject { helper.image_tag_or_inline_svg_tag("twitter", width: 18, height: 18) }

      it { is_expected.to include('width="18" height="18"') }
    end

    context "with #internal_navigation? set to false" do
      before { allow(helper).to receive(:internal_navigation?).and_return(false) }

      it { is_expected.to start_with('<svg xmlns="http://www.w3.org/2000/svg"') }
    end

    context "with width and height arguments, and with #internal_navigation? set to false" do
      subject { helper.image_tag_or_inline_svg_tag("twitter", width: 18, height: 18) }

      before { allow(helper).to receive(:internal_navigation?).and_return(false) }

      it { is_expected.to include('width="18" height="18"') }
    end
  end

  describe "#utc_iso_timestamp" do
    it "correctly formats the date when present" do
      expect(helper.utc_iso_timestamp(Time.current))
        .to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "returns nil if there is no timestamp" do
      expect(helper.utc_iso_timestamp(nil)).to be_nil
    end
  end

  describe ".comment_cue_message" do
    it "returns the zero-comment copy when count is 0" do
      expect(helper.comment_cue_message(0))
        .to eq(I18n.t("views.articles.comment_cue.zero"))
    end

    it "returns the few-comments copy for 1..10" do
      [1, 5, 10].each do |count|
        expect(helper.comment_cue_message(count))
          .to eq(I18n.t("views.articles.comment_cue.few"))
      end
    end

    it "returns the many-comments copy when count exceeds 10" do
      [11, 50, 999].each do |count|
        expect(helper.comment_cue_message(count))
          .to eq(I18n.t("views.articles.comment_cue.many"))
      end
    end

    it "treats nil as zero comments" do
      expect(helper.comment_cue_message(nil))
        .to eq(I18n.t("views.articles.comment_cue.zero"))
    end
  end

  describe "#has_vid?" do
    let(:article) { build(:article, processed_html: "<p>Hello world</p>", comments_count: 1) }

    it "returns true when article processed_html contains youtube without calling comments_blob" do
      article.processed_html = '<iframe src="https://www.youtube.com/embed/123"></iframe>'
      allow(article).to receive(:comments_blob)

      expect(helper.has_vid?(article)).to be(true)
      expect(article).not_to have_received(:comments_blob)
    end

    it "checks already-loaded comment trees in memory, including nested replies" do
      root = build(:comment, body_markdown: "Nice post")
      reply = build(:comment, body_markdown: "Check out https://www.youtube.com/watch?v=abc")
      allow(Comments::Tree).to receive(:for_commentable).and_return({ root => { reply => {} } })
      article.comment_tree(limit: 10, order: "top", include_negative: false)
      allow(article).to receive(:comments_blob)

      expect(helper.has_vid?(article)).to be(true)
      expect(article).not_to have_received(:comments_blob)
    end

    it "returns false from loaded comment trees without youtube links" do
      allow(Comments::Tree).to receive(:for_commentable).and_return({ build(:comment, body_markdown: "hi") => {} })
      article.comment_tree(limit: 10, order: "top", include_negative: false)
      allow(article).to receive(:comments_blob)

      expect(helper.has_vid?(article)).to be(false)
      expect(article).not_to have_received(:comments_blob)
    end

    it "returns false without calling comments_blob when comment counts are zero" do
      article.comments_count = 0
      article.displayed_comments_count = 0
      allow(article).to receive(:comments_blob)

      expect(helper.has_vid?(article)).to be(false)
      expect(article).not_to have_received(:comments_blob)
    end

    it "falls back to article.comments_blob when no comment tree has been loaded" do
      allow(article).to receive(:comments_blob).and_return("watch on youtube")

      expect(helper.has_vid?(article)).to be(true)
    end
  end

  describe "#should_show_updated_on?" do
    let(:article) do
      build(
        :article,
        published_from_feed: false,
        published_at: 1.hour.ago,
        edited_at: Time.current,
      ).tap { |a| a.published = true }
    end

    it "returns false when not published" do
      article.published = false
      expect(helper.should_show_updated_on?(article)).to be false
    end

    it "returns false when published from feed" do
      article.published_from_feed = true
      expect(helper.should_show_updated_on?(article)).to be false
    end

    it "returns false when edited_at is missing" do
      article.edited_at = nil
      expect(helper.should_show_updated_on?(article)).to be false
    end

    it "returns false when published_at is missing" do
      article.published_at = nil
      expect(helper.should_show_updated_on?(article)).to be false
    end

    it "returns true when edited_at is after published_at on the same day" do
      article.published_at = Time.current.beginning_of_day + 1.hour
      article.edited_at = article.published_at + 10.minutes
      expect(helper.should_show_updated_on?(article)).to be true
    end

    it "returns true when edited_at is after published_at on a later day" do
      article.published_at = 1.day.ago
      article.edited_at = Time.current
      expect(helper.should_show_updated_on?(article)).to be true
    end

    it "returns false when edited_at is before or equal to published_at" do
      article.published_at = Time.current
      article.edited_at = 1.day.ago
      expect(helper.should_show_updated_on?(article)).to be false
    end
  end

  describe "#feed_item_descriptions" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(memory_store) }

    it "batches cache misses into a single write_multi and skips Nokogiri unless panels or entities are present" do
      plain = build(:article, id: 101, processed_html: "<p>Hello world</p>")
      panel = build(:article, id: 102, processed_html: '<div class="highlight__panel">x</div><p>Code</p>')
      encoded_html = '<div class="highlight&#95;_panel">x</div><p>Encoded</p>'
      encoded_panel = build(:article, id: 103, processed_html: encoded_html)
      blank_article = build(:article, id: 104, processed_html: nil)

      allow(Nokogiri::HTML).to receive(:fragment).and_call_original
      allow(memory_store).to receive(:write_multi).and_call_original
      allow(memory_store).to receive(:write)

      descriptions = helper.feed_item_descriptions([plain, panel, encoded_panel, blank_article],
                                                   scrubber: FeedMarkdownScrubber.new)

      expect(descriptions).to eq(101 => "<p>Hello world</p>", 102 => "<p>Code</p>", 103 => "<p>Encoded</p>", 104 => "")
      expect(memory_store).to have_received(:write_multi).once
      expect(memory_store).not_to have_received(:write)
      expect(Nokogiri::HTML).to have_received(:fragment).twice
    end

    it "reuses cached descriptions across duplicate bodies while batching only misses" do
      warm_html = "<p>Cached body</p>"
      new_html = "<p>Fresh body</p>"
      helper.feed_item_descriptions([build(:article, id: 105, processed_html: warm_html)],
                                    scrubber: FeedMarkdownScrubber.new)

      allow(helper).to receive(:sanitize).and_call_original
      allow(memory_store).to receive(:write_multi).and_call_original

      first_cached = build(:article, id: 106, processed_html: warm_html)
      second_cached = build(:article, id: 107, processed_html: warm_html)
      uncached = build(:article, id: 108, processed_html: new_html)

      descriptions = helper.feed_item_descriptions([first_cached, second_cached, uncached],
                                                   scrubber: FeedMarkdownScrubber.new)

      new_key = "rss_feed_description/v1/#{Digest::MD5.hexdigest(new_html)}"
      expect(descriptions).to eq(106 => warm_html, 107 => warm_html, 108 => new_html)
      expect(helper).to have_received(:sanitize).with(new_html, scrubber: kind_of(FeedMarkdownScrubber)).once
      expect(memory_store).to have_received(:write_multi).with({ new_key => new_html },
                                                               hash_including(expires_in: 6.hours)).once
    end
  end
end
