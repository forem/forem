# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
require "rails_helper"

RSpec.describe Article, type: :model do
  def build_and_validate_article(*args)
    article = build(:article, *args)
    article.validate
    article
  end

  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  it { is_expected.to validate_uniqueness_of(:canonical_url).allow_blank }
  it { is_expected.to validate_uniqueness_of(:body_markdown).scoped_to(:user_id, :title) }
  it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:user_id) }
  it { is_expected.to validate_uniqueness_of(:feed_source_url).allow_blank }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:title).is_at_most(128) }
  it { is_expected.to validate_length_of(:cached_tag_list).is_at_most(86) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to belong_to(:collection) }
  it { is_expected.to have_many(:comments) }
  it { is_expected.to have_many(:reactions) }
  it { is_expected.to have_many(:notifications) }
  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.not_to allow_value("foo").for(:main_image_background_hex_color) }

  context "when published" do
    before do
      allow(subject).to receive(:published?).and_return(true) # rubocop:disable RSpec/NamedSubject
    end

    it { is_expected.to validate_presence_of(:slug) }
  end

  it "assigns published date if included in frontmatter" do
    expect(create(:article, with_date: true).published_at).not_to be_nil
  end

  it "reject future dates" do
    expect(build(:article, with_date: true, date: "01/01/2020").valid?).to be(false)
  end

  it "has proper username" do
    expect(article.username).to eq(article.user.username)
  end

  it "persists with valid data" do
    article.save
    expect(article.persisted?).to eq(true)
  end

  it "does not persist with invalid data" do
    bad_body = "hey hey hey hey hey hey"
    expect(build(:article, body_markdown: bad_body).valid?).to eq(false)
  end

  it "does not persist with invalid publish scoped data" do
    article = Article.create(title: "hey",
                             body_html: "hey hey hey hey hey hey",
                             published: true)
    expect(article.persisted?).to eq(false)
  end

  describe "#published_at" do
    let(:not_published_article) { build(:article, published: false) }

    before do
      not_published_article.validate
    end

    it "does not have a published_at if not published" do
      expect(not_published_article.published_at).to be_nil
    end

    it "does have a published_at if published" do
      article.validate
      expect(article.published_at).not_to be_nil
    end

    it "does not have crossposted_at if not published_from_feed" do
      expect(article.crossposted_at).to be_nil
    end

    it "does have crossposted_at if not published_from_feed" do
      article.published_from_feed = true
      article.save
      expect(article.crossposted_at).not_to be_nil
    end
  end

  describe "featured_number" do
    it "is updated if approved when already true" do
      body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello"
      article.body_markdown = body
      article.save
      article.approved = true
      article.save
      sleep(1)
      article.body_markdown = body + "s"
      article.approved = true
      article.save!
      expect(article.featured_number).not_to eq(article.updated_at.to_i)
    end
  end

  describe "#slug" do
    let(:title) { "hey This' is$ a SLUG" }
    let(:article0) { build(:article, title: title, published: false) }
    let(:article1) { build(:article, title: title, published: false) }

    before do
      article0.validate
    end

    context "when unpublished" do
      it "creates proper slug with this-is-the-slug format" do
        expect(article0.slug).to match /(.*-){4,}/
      end

      it "modifies slug on create if proposed slug already exists on the user" do
        article1.validate
        expect(article1.slug).not_to start_with(article0.slug)
      end
    end

    context "when published" do
      before { article0.update(published: true) }

      it "creates proper slug with this-is-the-slug format" do
        expect(article0.slug).to start_with("hey-this-is-a-slug")
      end

      it "does not change slug if the article was edited" do
        article0.update(title: "New title.")
        expect(article0.slug).to start_with("hey-this-is-a-slug")
      end
    end
  end

  context "when provided with body_markdown" do
    let(:test_article) { build(:article, title: title) }
    let(:title) { "Talk About It, Justify It" }
    let(:slug) { "talk-about-it-justify-it" }

    before { test_article.validate }

    describe "#title" do
      it "produces a proper title" do
        expect(test_article.title).to eq(title)
      end
    end

    describe "#slug" do
      it "produces a proper slug similar to the title" do
        expect(test_article.slug).to start_with(slug)
      end
    end

    describe "#tag" do
      it "parses tags" do
        expect(test_article.tag_list.length).to be > 0
      end

      it "accepts an empty tag list and returns empty array" do
        expect(build_and_validate_article(with_tags: false).tag_list).to eq([])
      end

      it "rejects if there are more than 4 tags" do
        five_tags = "one, two, three, four, five"
        expect(build(:article, tags: five_tags).valid?).to be(false)
      end
    end

    describe "#canonical_url" do
      let(:article_with_canon_url) { build(:article, with_canonical_url: true) }

      before do
        article_with_canon_url.validate
      end

      it "parses does not assign canonical_url" do
        expect(article.canonical_url).to eq(nil)
      end

      it "parses canonical_url if canonical_url is present" do
        expect(article_with_canon_url.canonical_url).not_to be_nil
      end

      it "parses does not remove canonical_url" do
        initial_link = article_with_canon_url.canonical_url
        article_with_canon_url.body_markdown = build(:article).body_markdown
        article_with_canon_url.validate
        expect(article_with_canon_url.canonical_url).to eq(initial_link)
      end
    end
  end

  describe "#video" do
    it "must be a url" do
      article.user.add_role(:video_permission)
      article.video = "hey"
      expect(article).not_to be_valid
      article.video = "http://hey.com"
      expect(article).to be_valid
    end

    it "must belong to permissioned user" do
      article.video = "http://hey.com"
      expect(article).not_to be_valid
      article.user.add_role(:video_permission)
      expect(article).to be_valid
    end
  end

  describe "queries" do
    let(:search_keyword) do
      create(:search_keyword,
        google_result_path: article.path,
        google_position: 8,
        google_volume: 2000,
        google_difficulty: 10)
    end

    it "returns article plucked objects that match keyword query" do
      search_keyword
      article.update(featured: true)
      articles = Article.seo_boostable
      expect(articles.flatten[0]).to eq(article.path)
    end

    it "returns keyword articles by tag" do
      search_keyword
      article.update(featured: true)
      articles = Article.seo_boostable(article.tags.first)
      expect(articles.flatten[0]).to eq(article.path)
    end

    it "does not return articles when none match based on tag" do
      search_keyword
      article.update(featured: true)
      articles = Article.seo_boostable("woozle-wozzle-20000")
      expect(articles.size).to eq(0)
    end

    it "doesn't return keywords that don't match criteria plucked objects matching keyword query" do
      search_keyword.update_attributes(google_position: 33) # too high of a position
      articles = Article.seo_boostable
      expect(articles.size).to eq(0)
    end

    it "does not return unpublished articles" do
      search_keyword
      articles = Article.seo_boostable
      article.update(published: false)
      expect(articles.size).to eq(0)
    end
    it "returns empty relation if no articles match" do
      articles = Article.seo_boostable
      expect(articles.size).to eq(0)
    end
  end

  it "detects no liquid tag if not used" do
    expect(article.decorate.liquid_tags_used).to eq([])
  end

  it "returns article title length classification" do
    article.title = "0" * 106
    expect(article.decorate.title_length_classification).to eq("longest")
    article.title = "0" * 81
    expect(article.decorate.title_length_classification).to eq("longer")
    article.title = "0" * 61
    expect(article.decorate.title_length_classification).to eq("long")
    article.title = "0" * 23
    expect(article.decorate.title_length_classification).to eq("medium")
    article.title = "0" * 20
    expect(article.decorate.title_length_classification).to eq("short")
  end

  it "returns stripped canonical url" do
    article.canonical_url = " http://google.com "
    expect(article.decorate.processed_canonical_url).to eq("http://google.com")
  end

  it "gets search indexed" do
    article = create(:article)
    article.index!
  end

  it "removes from search index" do
    article = create(:article)
    article.remove_algolia_index
  end

  it "detects liquid tags used", :vcr do
    VCR.use_cassette("twitter_gem") do
      article = build_and_validate_article(with_tweet_tag: true)
      expect(article.decorate.liquid_tags_used).to eq([TweetTag])
    end
  end

  it "fixes the issue with --- hr tags" do
    article = build_and_validate_article(with_hr_issue: true)
    expect(article.processed_html.include?("<hr")).to be(true)
  end

  describe "#body_text" do
    it "return a sanitized processed_html" do
      article.validate
      expect(article.body_text).to eq(
        ActionView::Base.full_sanitizer.sanitize(article.processed_html),
      )
    end
  end

  it "has a valid search_score" do
    expect(article.search_score).to be_a(Integer)
  end

  describe "#index_id" do
    it "returns proper string" do
      article.validate
      expect(article.index_id).to eq("articles-#{article.id}")
    end
  end

  describe "::filter_excluded_tags" do
    before do
      create(:article, tags: "hiring")
    end

    it "exlude #hiring when no argument is given" do
      expect(described_class.filter_excluded_tags.length).to be(0)
    end

    it "filters #hiring articles when argument is 'hiring'" do
      # this is not checking for newest article
      expect(described_class.filter_excluded_tags("hiring").length).to be(1)
    end

    it "filters the tag it is asked to filter" do
      create(:article, tags: "filter")
      expect(described_class.filter_excluded_tags("filter").length).to be(1)
    end
  end

  describe "#flare_tag" do
    it "returns nil if there is no flare tag" do
      expect(FlareTag.new(article).tag).to be nil
    end

    it "returns a flare tag if there is a flare tag in the list" do
      valid_article = create(:article, tags: "ama")
      expect(FlareTag.new(valid_article).tag.name).to eq("ama")
    end
  end

  describe "#flare_tag_hash" do
    let (:tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
    let (:valid_article) { create(:article, tags: tag.name) }

    it "returns nil if an article doesn't have a flare tag" do
      expect(FlareTag.new(article).tag_hash).to be nil
    end

    it "returns a hash with the flare tag's name" do
      expect(FlareTag.new(valid_article).tag_hash.value?("ama")).to be true
    end

    it "returns a hash with the flare tag's bg_color_hex" do
      expect(FlareTag.new(valid_article).tag_hash.value?("#f3f3f3")).to be true
    end

    it "returns a hash with the flare tag's text_color_hex" do
      expect(FlareTag.new(valid_article).tag_hash.value?("#cccccc")).to be true
    end
  end

  describe "before save" do
    # before do
    #   article = create(:article, user_id: user.id)
    # end
    it "assigns path on save" do
      article = create(:article, user_id: user.id)
      expect(article.path).to eq("/#{article.username}/#{article.slug}")
    end
    it "assigns cached_user_name on save" do
      article = create(:article, user_id: user.id)
      expect(article.cached_user_name).to eq(article.cached_user_name)
    end
    it "assigns cached_user_username on save" do
      article = create(:article, user_id: user.id)
      expect(article.cached_user_username).to eq(article.user_username)
    end
  end

  describe "validations" do
    it "must have url for main image if present" do
      article.main_image_background_hex_color = "hello"
      expect(article.valid?).to eq(false)
      article.main_image_background_hex_color = "#fff000"
      expect(article.valid?).to eq(true)
    end

    it "must have true hex for image background" do
      article.main_image = "hello"
      expect(article.valid?).to eq(false)
      article.main_image = "https://image.com/image.png"
      expect(article.valid?).to eq(true)
    end
  end

  it "updates main_image_background_hex_color" do
    article = build(:article)
    allow(article).to receive(:update_main_image_background_hex).and_call_original
    article.save
    expect(article).to have_received(:update_main_image_background_hex)
  end

  describe "#async_score_calc" do
    context "when published" do
      let(:article) { create(:article) }

      it "updates the hotness score" do
        article.save
        expect(article.hotness_score > 0).to eq(true)
      end

      it "updates the spaminess score" do
        article.update_column(:spaminess_rating, -1)
        article.save
        expect(article.spaminess_rating).to eq(0)
      end
    end

    context "when unpublished" do
      let(:article) { create(:article, published: false) }

      it "does not update the hotness score" do
        article.save
        expect(article.hotness_score).to eq(0)
      end

      it "does not update the spaminess score" do
        article.update_column(:spaminess_rating, -1)
        article.save
        expect(article.spaminess_rating).to eq(-1)
      end
    end
  end

  it "detects detect_human_language" do
    article.save
    article.detect_human_language
    expect(article.language).not_to be_empty
  end

  it "returns class name" do
    expect(article.class_name).to eq("Article")
  end

  it "does not show year in readable time if not current year" do
    time_now = Time.current
    article.published_at = time_now
    expect(article.readable_publish_date).to eq(time_now.strftime("%b %e"))
  end

  it "shows year in readable time if not current year" do
    article.published_at = 1.years.ago
    last_year = 1.year.ago.year % 100
    expect(article.readable_publish_date.include?("'#{last_year}")).to eq(true)
  end

  it "is valid as part of a collection" do
    collection = Collection.create(user_id: article.user.id, slug: "yoyoyo")
    article.collection_id = collection.id
    expect(article).to be_valid
  end

  it "is not valid as part of a collection that does not belong to user" do
    collection = Collection.create(user_id: 32443, slug: "yoyoyo")
    article.collection_id = collection.id
    expect(article).not_to be_valid
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
