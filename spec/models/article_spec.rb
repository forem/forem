require "rails_helper"

RSpec.describe Article, type: :model do
  def build_and_validate_article(*args)
    article = build(:article, *args)
    article.validate!
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
  it { is_expected.to validate_length_of(:cached_tag_list).is_at_most(126) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:organization).optional }
  it { is_expected.to belong_to(:collection).optional }
  it { is_expected.to have_many(:comments) }
  it { is_expected.to have_many(:reactions) }
  it { is_expected.to have_many(:notifications) }
  it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }
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
    article = described_class.create(title: "hey",
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
      article0.validate!
    end

    context "when unpublished" do
      it "creates proper slug with this-is-the-slug format" do
        expect(article0.slug).to match(/(.*-){4,}/)
      end

      it "modifies slug on create if proposed slug already exists on the user" do
        article1.validate
        expect(article1.slug).not_to start_with(article0.slug)
      end

      it "properly converts underscores and still has a valid slug" do
        underscored_article = build(:article, title: "hey_hey_hey node_modules", published: false)
        expect(underscored_article.valid?).to eq true
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

      it "properly converts underscores and still has a valid slug" do
        underscored_article = build(:article, title: "hey_hey_hey node_modules", published: true)
        expect(underscored_article.valid?).to eq true
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

      it "rejects if there are tags with length > 30" do
        tags = "'testing tag length with more than 30 chars', tag"
        expect(build(:article, tags: tags).valid?).to be(false)
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

    describe "#reading_time" do
      it "produces a correct reading time" do
        expect(test_article.reading_time).to eq(1)
      end
    end
  end

  describe "#video" do
    it "must be a url" do
      article.user.created_at = 3.weeks.ago
      article.video = "hey"
      expect(article).not_to be_valid
      article.video = "http://hey.com"
      expect(article).to be_valid
    end

    it "must belong to permissioned user" do
      article.video = "http://hey.com"
      expect(article).not_to be_valid
      article.user.created_at = 3.weeks.ago
      expect(article).to be_valid
    end

    it "saves with video" do
      article.user.created_at = 3.weeks.ago
      article.video = "https://s3.amazonaws.com/dev-to-input-v0/video-upload__2d7dc29e39a40c7059572bca75bb646b"
      article.save
      expect(article).to be_valid
    end

    it "has padded video_duration_in_minutes" do
      article.video_duration_in_seconds = 1141
      expect(article.video_duration_in_minutes).to eq("19:01")
    end

    it "has correctly non-padded seconds in video_duration_in_minutes" do
      article.video_duration_in_seconds = 1161
      expect(article.video_duration_in_minutes).to eq("19:21")
    end

    it "has video_duration_in_minutes display hour when video is an hour or longer" do
      article.video_duration_in_seconds = 3600
      expect(article.video_duration_in_minutes).to eq("1:00:00")
    end

    it "has correctly non-padded minutes with hour in video_duration_in_minutes" do
      article.video_duration_in_seconds = 5000
      expect(article.video_duration_in_minutes).to eq("1:23:20")
    end
  end

  describe ".seo_boostable" do
    it "returns articles ordered by organic_page_views_count" do
      create(:article, score: 30)
      create(:article, score: 30)
      top_article = create(:article, organic_page_views_past_month_count: 20, score: 30)
      articles = described_class.seo_boostable
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns articles if within time frame" do
      top_article = create(:article, organic_page_views_past_month_count: 20, score: 30)
      articles = described_class.seo_boostable(nil, 1.month.ago)
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "does not return articles outside of timeframe" do
      top_article = create(:article, organic_page_views_past_month_count: 20, score: 30)
      top_article.update_column(:published_at, 3.months.ago)
      articles = described_class.seo_boostable(nil, 1.month.ago)
      expect(articles.first).to eq(nil)
    end

    it "returns articles ordered by organic_page_views_count by tag" do
      create(:article, score: 30)
      create(:article, organic_page_views_count: 30, score: 30)
      top_article = create(:article, organic_page_views_past_month_count: 20, score: 30)
      top_article.update_column(:cached_tag_list, "good, greatalicious")
      articles = described_class.seo_boostable("greatalicious")
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns nothing if no tagged articles" do
      create(:article, score: 30)
      create(:article, organic_page_views_count: 30)
      top_article = create(:article, organic_page_views_past_month_count: 20, score: 30)
      top_article.update_column(:cached_tag_list, "good, greatalicious")
      articles = described_class.seo_boostable("godsdsdsdsgoo")
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

  it "determines that an article has frontmatter" do
    body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello"
    article.body_markdown = body
    expect(article.has_frontmatter?).to eq(true)
  end

  it "determines that an article doesn't have frontmatter" do
    body = "Hey hey Ho Ho"
    article.body_markdown = body
    expect(article.has_frontmatter?).to eq(false)
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
    it "assigns cached_user on save" do
      article = create(:article, user_id: user.id)
      expect(article.cached_user.username).to eq(article.user.username)
      expect(article.cached_user.name).to eq(article.user.name)
      expect(article.cached_user.profile_image_url).to eq(article.user.profile_image_url)
      expect(article.cached_user.profile_image_90).to eq(article.user.profile_image_90)
    end
    it "assigns cached_organization on save" do
      organization = create(:organization)
      article = create(:article, user_id: user.id, organization_id: organization.id)
      expect(article.cached_organization.username).to eq(article.organization.username)
      expect(article.cached_organization.name).to eq(article.organization.name)
      expect(article.cached_organization.slug).to eq(article.organization.slug)
      expect(article.cached_organization.profile_image_90).to eq(article.organization.profile_image_90)
      expect(article.cached_organization.profile_image_url).to eq(article.organization.profile_image_url)
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

    it "does not allow the use of admin-only liquid tags for non-admins" do
      poll = create(:poll, article_id: article.id)
      article.body_markdown = "hello hey hey hey {% poll #{poll.id} %}"
      expect(article.valid?).to eq(false)
    end

    it "allows admins" do
      poll = create(:poll, article_id: article.id)
      article.user.add_role(:admin)
      article.body_markdown = "hello hey hey hey {% poll #{poll.id} %}"
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
      let(:article) { build(:article) }

      it "updates the hotness score" do
        perform_enqueued_jobs do
          article.save
          expect(article.reload.hotness_score.positive?).to eq(true)
        end
      end

      it "updates the spaminess rating" do
        perform_enqueued_jobs do
          article.spaminess_rating = -1
          article.save
          expect(article.reload.spaminess_rating).to eq(0)
        end
      end
    end

    context "when unpublished" do
      let(:article) { create(:article, published: false) }

      it "does not update the hotness score" do
        perform_enqueued_jobs do
          article.save
          expect(article.reload.hotness_score).to eq(0)
        end
      end

      it "does not update the spaminess rating" do
        perform_enqueued_jobs do
          article.spaminess_rating = -1
          article.save
          expect(article.reload.spaminess_rating).to eq(-1)
        end
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

  describe "readable_edit_date" do
    it "returns nil if article is not edited" do
      expect(article.readable_edit_date).to be_nil
    end

    it "does not show year in readable time if not current year" do
      time_now = Time.current
      article.edited_at = time_now
      expect(article.readable_edit_date).to eq(time_now.strftime("%b %e"))
    end

    it "shows year in readable time if not current year" do
      article.edited_at = 1.year.ago
      last_year = 1.year.ago.year % 100
      expect(article.readable_edit_date.include?("'#{last_year}")).to eq(true)
    end
  end

  describe "readable_publish_date" do
    it "does not show year in readable time if not current year" do
      time_now = Time.current
      article.published_at = time_now
      expect(article.readable_publish_date).to eq(time_now.strftime("%b %e"))
    end

    it "shows year in readable time if not current year" do
      article.published_at = 1.year.ago
      last_year = 1.year.ago.year % 100
      expect(article.readable_publish_date.include?("'#{last_year}")).to eq(true)
    end
  end

  it "is valid as part of a collection" do
    collection = Collection.create(user_id: article.user.id, slug: "yoyoyo")
    article.collection_id = collection.id
    expect(article).to be_valid
  end

  describe "comment templates" do
    it "can have no template" do
      expect(build(:article).valid?).to be(true)
    end

    it "can have a template" do
      expect(build(:article, comment_template: "my comment template").comment_template).to eq("my comment template")
    end
  end

  describe "published_timestamp" do
    it "returns empty string if the article is new" do
      expect(described_class.new.published_timestamp).to eq("")
    end

    it "returns empty string if the article is not published" do
      article.update_column(:published, false)
      expect(article.published_timestamp).to eq("")
    end

    it "returns the timestamp of the crossposting date over the publishing date" do
      crossposted_at = 1.week.ago
      published_at = 1.day.ago
      article.update_columns(
        published: true, crossposted_at: crossposted_at, published_at: published_at,
      )
      expect(article.published_timestamp).to eq(crossposted_at.utc.iso8601)
    end

    it "returns the timestamp of the publishing date if there is no crossposting date" do
      published_at = 1.day.ago
      article.update_columns(published: true, crossposted_at: nil, published_at: published_at)
      expect(article.published_timestamp).to eq(published_at.utc.iso8601)
    end
  end

  describe "when algolia auto-indexing/removal is triggered" do
    context "when article is saved" do
      it "process background auto-indexing" do
        expect { build(:article, user_id: user.id).save }.to have_enqueued_job.with(kind_of(described_class), "index_or_remove_from_index_where_appropriate").on_queue("algoliasearch")
      end
    end

    context "when article is to be deleted" do
      it "does nothing" do
        # So that job triggered at creation outside of scope
        # And test only on destroy, and nothing should be triggered
        current_article = article
        expect { current_article.destroy }.not_to have_enqueued_job.with(kind_of(Hash), "index_or_remove_from_index_where_appropriate").on_queue("algoliasearch")
      end
    end
  end

  include_examples "#sync_reactions_count", :article
end
