require "rails_helper"

RSpec.describe Article, type: :model do
  def build_and_validate_article(*args)
    article = build(:article, *args)
    article.validate!
    article
  end

  let_it_be(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }

  include_examples "#sync_reactions_count", :article

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:canonical_url).allow_blank }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:user_id) }
    it { is_expected.to validate_uniqueness_of(:feed_source_url).allow_blank }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(128) }
    it { is_expected.to validate_length_of(:cached_tag_list).is_at_most(126) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to belong_to(:collection).optional }
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:notifications).dependent(:delete_all) }
    it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.not_to allow_value("foo").for(:main_image_background_hex_color) }

    describe "#after_commit" do
      it "on update enqueues job to index article to elasticsearch" do
        article.save
        sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: [described_class.to_s, article.search_id]) do
          article.save
        end
      end

      it "on destroy enqueues job to delete article from elasticsearch" do
        article = create(:article)

        sidekiq_assert_enqueued_with(job: Search::RemoveFromElasticsearchIndexWorker, args: [described_class::SEARCH_CLASS.to_s, article.search_id]) do
          article.destroy
        end
      end
    end

    describe "#after_update_commit" do
      it "if article is unpublished removes reading list reactions from index" do
        reaction = create(:reaction, reactable: article, category: "readinglist")
        sidekiq_perform_enqueued_jobs
        expect(reaction.elasticsearch_doc).not_to be_nil

        unpublished_body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: false\ntags: hiring\n---\n\nHello"
        article.update(body_markdown: unpublished_body)
        sidekiq_perform_enqueued_jobs
        expect { reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
      end

      it "if article is published indexes reading list reactions" do
        reaction = create(:reaction, reactable: article, category: "readinglist")
        sidekiq_perform_enqueued_jobs
        unpublished_body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: false\ntags: hiring\n---\n\nHello"
        article.update(body_markdown: unpublished_body)
        sidekiq_perform_enqueued_jobs
        expect { reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)

        published_body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello"
        article.update(body_markdown: published_body)
        sidekiq_perform_enqueued_jobs
        expect(reaction.elasticsearch_doc).not_to be_nil
      end

      it "indexes reaction if a REACTION_INDEXED_FIELDS is changed" do
        reaction = create(:reaction, reactable: article, category: "readinglist")
        allow(article).to receive(:index_to_elasticsearch)
        allow(article.user).to receive(:index_to_elasticsearch)

        sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: ["Reaction", reaction.search_id]) do
          article.update(body_markdown: "---\ntitle: NEW TITLE#{rand(1000)}\n")
        end
      end
    end

    context "when published" do
      before do
        # rubocop:disable RSpec/NamedSubject
        allow(subject).to receive(:published?).and_return(true)
        # rubocop:enable RSpec/NamedSubject
      end

      it { is_expected.to validate_presence_of(:slug) }
    end

    describe "#search_id" do
      it "returns article_ID" do
        expect(article.search_id).to eq("article_#{article.id}")
      end
    end

    describe "#main_image_background_hex_color" do
      it "must have true hex for image background" do
        article.main_image_background_hex_color = "hello"
        expect(article.valid?).to eq(false)
        article.main_image_background_hex_color = "#fff000"
        expect(article.valid?).to eq(true)
      end
    end

    describe "#canonical_url_must_not_have_spaces" do
      let!(:article) { build :article, user: user }

      it "is valid without spaces" do
        valid_url = "https://www.positronx.io/angular-radio-buttons-example/"
        article.canonical_url = valid_url

        expect(article).to be_valid
      end

      it "is not valid with spaces" do
        invalid_url = "https://www.positronx.io/angular radio-buttons-example/"
        article.canonical_url = invalid_url
        messages = ["must not have spaces"]

        expect(article).not_to be_valid
        expect(article.errors.messages[:canonical_url]).to eq messages
      end
    end

    describe "#main_image" do
      it "must have url for main image if present" do
        article.main_image = "hello"
        expect(article.valid?).to eq(false)
        article.main_image = "https://image.com/image.png"
        expect(article.valid?).to eq(true)
      end
    end

    describe "dates" do
      it "reject future dates" do
        expect(build(:article, with_date: true, date: Date.tomorrow).valid?).to be(false)
      end

      it "reject future dates even when it's published at" do
        article.published_at = Date.tomorrow
        expect(article.valid?).to be(false)
      end
    end

    describe "polls" do
      let!(:poll) { create(:poll, article: article) }

      it "does not allow the use of admin-only liquid tags for non-admins" do
        article.body_markdown = "hello hey hey hey {% poll #{poll.id} %}"
        expect(article.valid?).to eq(false)
      end

      it "allows admins" do
        article.user.add_role(:admin)
        article.body_markdown = "hello hey hey hey {% poll #{poll.id} %}"
        expect(article.valid?).to eq(true)
      end
    end

    describe "liquid tags" do
      it "is not valid if it contains invalid liquid tags" do
        body = "{% github /thepracticaldev/dev.to %}"
        article = build(:article, body_markdown: body)
        expect(article).not_to be_valid
        expect(article.errors[:base]).to eq(["Invalid Github Repo link"])
      end

      it "is valid with valid liquid tags", :vcr do
        VCR.use_cassette("twitter_fetch_status") do
          article = build_and_validate_article(with_tweet_tag: true)
          expect(article).to be_valid
        end
      end
    end

    describe "tag validation" do
      let(:article) { build(:article, user: user) }

      # See https://github.com/thepracticaldev/dev.to/pull/6302
      # rubocop:disable RSpec/VerifiedDoubles
      it "does not modify the tag list if there are no adjustments" do
        allow(TagAdjustment).to receive(:where).and_return(TagAdjustment.none)
        allow(article).to receive(:tag_list).and_return(spy("tag_list"))

        article.save

        # We expect this to happen once in #evaluate_front_matter
        expect(article.tag_list).to have_received(:add).once
        expect(article.tag_list).not_to have_received(:remove)
      end
      # rubocop:enable RSpec/VerifiedDoubles
    end
  end

  context "when data is extracted from evaluation of the front matter during validation" do
    let!(:title) { "Talk About It, Justify It" }
    let!(:slug) { "talk-about-it-justify-it" }
    let!(:test_article) { build(:article, title: title) }

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
        expect(test_article.tag_list.length.positive?).to be(true)
      end

      it "accepts an empty tag list and returns empty array" do
        expect(build_and_validate_article(with_tags: false).tag_list).to be_empty
      end

      it "rejects more than 4 tags" do
        five_tags = "one, two, three, four, five"
        expect(build(:article, tags: five_tags).valid?).to be(false)
      end

      it "rejects tags with length > 30" do
        tags = "'testing tag length with more than 30 chars', tag"
        expect(build(:article, tags: tags).valid?).to be(false)
      end

      it "parses tags when description is empty" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: one\n---\n\n"
        expect(build_and_validate_article(body_markdown: body_markdown).tag_list).to eq(["one"])
      end
    end

    describe "#description" do
      it "creates proper description when description is present" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription: hey hey hoho\ntags: one\n---\n\n"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to eq("hey hey hoho")
      end

      it "creates proper description when description is not present and body is present and short, with no tags" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags:\n---\n\nThis is the body yo"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to eq("This is the body yo")
      end

      it "creates proper description when description is not present and body is present and short" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag\n---\n\nThis is the body yo"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to eq("This is the body yo")
      end

      it "creates proper description when description is not present and body is present and long" do
        paragraphs = Faker::Hipster.paragraph(sentence_count: 40)
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags:\n---\n\n#{paragraphs}"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to end_with("...")
      end
    end

    describe "#canonical_url" do
      let!(:article_with_canon_url) { build(:article, with_canonical_url: true) }

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

    describe "#processed_html" do
      it "fixes the issue with --- hr tags" do
        article = build_and_validate_article(with_hr_issue: true)
        expect(article.processed_html.include?("<hr")).to be(true)
      end
    end

    describe "#body_text" do
      it "return a sanitized version of processed_html" do
        sanitized_html = ActionView::Base.full_sanitizer.sanitize(test_article.processed_html)
        expect(test_article.body_text).to eq(sanitized_html)
      end
    end

    context "when a main_image does not already exist" do
      let!(:article_without_main_image) { build(:article, with_main_image: false) }
      let(:image) { Faker::Avatar.image }

      before { article_without_main_image.validate }

      it "can parse the main_image" do
        expect(article_without_main_image.main_image).to eq(nil)
      end

      it "can parse the main_image when added" do
        article_without_main_image.main_image = image
        article_without_main_image.validate

        expect(article_without_main_image.main_image).to eq(image)
      end
    end

    context "when a main_image exists" do
      # The `with_main_image` flag is the factory default, but we're being explicit here.
      let!(:article_with_main_image) { build(:article, with_main_image: true) }
      let(:image) { article_with_main_image.main_image }

      before { article_with_main_image.validate }

      it "can parse the main_image" do
        expect(article_with_main_image.main_image).to eq(image)
      end

      it "can parse the main_image when removed" do
        article_with_main_image.main_image = nil
        article_with_main_image.validate

        expect(article_with_main_image.main_image).to eq(nil)
      end

      it "can parse the main_image when changed" do
        expect(article_with_main_image.main_image).to eq(image)

        other_image = Faker::Avatar.image
        article_with_main_image.main_image = other_image
        article_with_main_image.validate
        expect(article_with_main_image.main_image).to eq(other_image)
      end
    end
  end

  describe "#class_name" do
    it "returns class name" do
      expect(article.class_name).to eq("Article")
    end
  end

  describe "#published_at" do
    it "does not have a published_at if not published" do
      unpublished_article = build(:article, published: false)
      unpublished_article.validate # to make sure the front matter extraction happens
      expect(unpublished_article.published_at).to be_nil
    end

    it "does have a published_at if published" do
      # this works because validation triggers the extraction of the date from the front matter
      article.validate
      expect(article.published_at).not_to be_nil
    end
  end

  describe "#nth_published_by_author" do
    it "does not have a nth_published_by_author if not published" do
      unpublished_article = build(:article, published: false)
      unpublished_article.validate # to make sure the front matter extraction happens
      expect(unpublished_article.nth_published_by_author).to eq(0)
    end

    it "does have a nth_published_by_author if published" do
      # this works because validation triggers the extraction of the date from the front matter
      published_article = create(:article, published: true, user: user)
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size)
      second_article = create(:article, user_id: published_article.user_id)
      expect(second_article.reload.nth_published_by_author).to eq(user.articles.size)
    end

    it "adds have a nth_published_by_author if published" do
      # this works because validation triggers the extraction of the date from the front matter
      published_article = create(:article, published: true, user: user)
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size)
      second_article = create(:article, user_id: published_article.user_id)
      second_article.update_column(:nth_published_by_author, 0)
      second_article.save
      expect(second_article.reload.nth_published_by_author).to eq(user.articles.size)
    end

    it "adds have a nth_published_by_author to earlier posts if added for first time" do
      # this works because validation triggers the extraction of the date from the front matter
      published_article = create(:article, published: true, user: user)
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size)
      create(:article, user_id: published_article.user_id)
      published_article.update_column(:nth_published_by_author, 0)
      published_article.save
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size - 1)
    end
  end

  describe "#crossposted_at" do
    it "does not have crossposted_at if not published_from_feed" do
      expect(article.crossposted_at).to be_nil
    end

    it "does have crossposted_at if not published_from_feed" do
      article.update(published_from_feed: true)
      expect(article.crossposted_at).not_to be_nil
    end
  end

  describe "#featured_number" do
    it "is updated if approved when already true" do
      body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello"
      article.update(body_markdown: body, approved: true)

      Timecop.travel(1.second.from_now) do
        article.update(body_markdown: body + "s")
      end

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

  describe "#username" do
    it "returns the user's username" do
      expect(article.username).to eq(user.username)
    end

    it "returns the organization slug if the article belongs to an organization" do
      article.organization = build(:organization)
      expect(article.username).to eq(article.organization.slug)
    end
  end

  describe "#has_frontmatter?" do
    it "returns true if the article has a frontmatter" do
      body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello"
      article.body_markdown = body
      expect(article.has_frontmatter?).to eq(true)
    end

    it "returns false if the article does not have a frontmatter" do
      article.body_markdown = "Hey hey Ho Ho"
      expect(article.has_frontmatter?).to eq(false)
    end

    it "returns true if parser raises a Psych::DisallowedClass error" do
      allow(FrontMatterParser::Parser).to receive(:new).and_raise(Psych::DisallowedClass.new("msg"))
      expect(article.has_frontmatter?).to eq(true)
    end

    it "returns true if parser raises a Psych::SyntaxError error" do
      syntax_error = Psych::SyntaxError.new("file", 1, 1, 0, "problem", "context")
      allow(FrontMatterParser::Parser).to receive(:new).and_raise(syntax_error)
      expect(article.has_frontmatter?).to eq(true)
    end
  end

  describe "#readable_edit_date" do
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

  describe "#readable_publish_date" do
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

  describe "#published_timestamp" do
    it "returns empty string if the article is not published" do
      article.published = false
      expect(article.published_timestamp).to be_empty
    end

    it "returns the timestamp of the crossposting date over the publishing date" do
      crossposted_at = 1.week.ago
      published_at = 1.day.ago
      article.published = true
      article.crossposted_at = crossposted_at
      article.published_at = published_at
      expect(article.published_timestamp).to eq(crossposted_at.utc.iso8601)
    end

    it "returns the timestamp of the publishing date if there is no crossposting date" do
      published_at = 1.day.ago
      article.published = true
      article.crossposted_at = nil
      article.published_at = published_at
      expect(article.published_timestamp).to eq(published_at.utc.iso8601)
    end
  end

  describe "#video" do
    before do
      user.created_at = 3.weeks.ago
      article.video = "https://youtube.com"
    end

    it "is not valid with a non url" do
      article.video = "hey"
      expect(article).not_to be_valid
    end

    it "is not valid if the user is too recent" do
      user.created_at = Time.current
      expect(article).not_to be_valid
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

  describe "#index_id" do
    it "is equal to articles-ID" do
      # NOTE: we shouldn't test private things but cheating a bit for Algolia here
      expect(article.send(:index_id)).to eq("articles-#{article.id}")
    end
  end

  describe ".seo_boostable" do
    let!(:top_article) do
      create(:article, organic_page_views_past_month_count: 20, score: 30, tags: "good, greatalicious", user: user)
    end

    it "returns articles ordered by organic_page_views_count" do
      articles = described_class.seo_boostable
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns articles if within time frame" do
      articles = described_class.seo_boostable(nil, 1.month.ago)
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "does not return articles outside of timeframe" do
      articles = described_class.seo_boostable(nil, 1.month.from_now)
      expect(articles).to be_empty
    end

    it "returns articles ordered by organic_page_views_count by tag" do
      articles = described_class.seo_boostable("greatalicious")
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns nothing if no tagged articles" do
      articles = described_class.seo_boostable("godsdsdsdsgoo")
      expect(articles).to be_empty
    end
  end

  context "when indexing and deindexing" do
    it "deindexes unpublished article from Article index" do
      sidekiq_assert_enqueued_with(job: Search::RemoveFromIndexWorker, args: [described_class.algolia_index_name, article.id]) do
        article.update(body_markdown: "---\ntitle: Title\npublished: false\ndescription:\ntags: one\n---\n\n")
      end
    end

    it "deindexes unpublished article from searchables index" do
      sidekiq_assert_enqueued_with(job: Search::RemoveFromIndexWorker, args: ["searchables_#{Rails.env}", article.index_id]) do
        article.update(body_markdown: "---\ntitle: Title\npublished: false\ndescription:\ntags: one\n---\n\n")
      end
    end

    it "deindexes unpublished article from ordered_articles index" do
      sidekiq_assert_enqueued_with(job: Search::RemoveFromIndexWorker, args: ["ordered_articles_#{Rails.env}", article.index_id]) do
        article.update(body_markdown: "---\ntitle: Title\npublished: false\ndescription:\ntags: one\n---\n\n")
      end
    end

    it "deindexes hiring article from Article index" do
      sidekiq_assert_enqueued_with(job: Search::RemoveFromIndexWorker, args: [described_class.algolia_index_name, article.id]) do
        article.update(body_markdown: "---\ntitle: Title\npublished: true\ndescription:\ntags: hiring\n---\n\n")
      end
    end

    it "deindexes hiring article from searchables index" do
      sidekiq_assert_enqueued_with(job: Search::RemoveFromIndexWorker, args: ["searchables_#{Rails.env}", article.index_id]) do
        article.update(body_markdown: "---\ntitle: Title\npublished: true\ndescription:\ntags: hiring\n---\n\n")
      end
    end

    it "deindexes hiring article from ordered_articles index" do
      sidekiq_assert_enqueued_with(job: Search::RemoveFromIndexWorker, args: ["ordered_articles_#{Rails.env}", article.index_id]) do
        article.update(body_markdown: "---\ntitle: Title\npublished: true\ndescription:\ntags: hiring\n---\n\n")
      end
    end

    it "indexes published non-hiring article" do
      sidekiq_assert_enqueued_with(job: Search::IndexWorker, args: ["Article", article.id]) do
        article.update(published: false)
      end
    end

    it "triggers auto removal from index on destroy" do
      article = create(:article)

      allow(article).to receive(:remove_from_index!)
      allow(article).to receive(:delete_related_objects)
      article.destroy
      expect(article).to have_received(:remove_from_index!)
      expect(article).to have_received(:delete_related_objects)
    end
  end

  context "when callbacks are triggered before save" do
    it "assigns path on save" do
      expect(article.path).to eq("/#{article.username}/#{article.slug}")
    end

    it "assigns cached_user_name on save" do
      expect(article.cached_user_name).to eq(article.user_name)
    end

    it "assigns cached_user_username on save" do
      expect(article.cached_user_username).to eq(article.user_username)
    end

    it "assigns cached_user on save" do
      expect(article.cached_user.name).to eq(article.user.name)
      expect(article.cached_user.username).to eq(article.user.username)
      expect(article.cached_user.slug).to eq(article.user.username)
      expect(article.cached_user.profile_image_90).to eq(article.user.profile_image_90)
      expect(article.cached_user.profile_image_url).to eq(article.user.profile_image_url)
      expect(article.cached_user.pro).to eq(article.user.pro?)
    end

    it "assigns cached_organization on save" do
      article = create(:article, user: user, organization: create(:organization))
      expect(article.cached_organization.name).to eq(article.organization.name)
      expect(article.cached_organization.username).to eq(article.organization.username)
      expect(article.cached_organization.slug).to eq(article.organization.slug)
      expect(article.cached_organization.profile_image_90).to eq(article.organization.profile_image_90)
      expect(article.cached_organization.profile_image_url).to eq(article.organization.profile_image_url)
      expect(article.cached_organization.pro).to be(false)
    end
  end

  context "when callbacks are triggered after save" do
    describe "main image background color" do
      let(:article) { build(:article, user: user) }

      it "enqueues a job to update the main image background if #dddddd" do
        article.main_image_background_hex_color = "#dddddd"
        allow(article).to receive(:update_main_image_background_hex).and_call_original
        sidekiq_assert_enqueued_with(job: Articles::UpdateMainImageBackgroundHexWorker) do
          article.save
        end
        expect(article).to have_received(:update_main_image_background_hex)
      end

      it "does not enqueue a job to update the main image background if not #dddddd" do
        article.main_image_background_hex_color = "#fff000"
        allow(article).to receive(:update_main_image_background_hex).and_call_original
        sidekiq_assert_no_enqueued_jobs(only: Articles::UpdateMainImageBackgroundHexWorker) do
          article.save
        end
        expect(article).to have_received(:update_main_image_background_hex)
      end
    end

    describe "async score calc" do
      it "enqueues Articles::ScoreCalcWorker if published" do
        sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker, args: [article.id]) do
          article.save
        end
      end

      it "does not enqueue Articles::ScoreCalcWorker if not published" do
        article = build(:article, published: false)
        sidekiq_assert_no_enqueued_jobs(only: Articles::ScoreCalcWorker) do
          article.save
        end
      end
    end

    describe "detect human language" do
      let(:language_detector) { instance_double(LanguageDetector) }

      before do
        allow(LanguageDetector).to receive(:new).and_return(language_detector)
        allow(language_detector).to receive(:detect)
      end

      it "calls the human language detector" do
        article.language = ""
        article.save

        expect(language_detector).to have_received(:detect)
      end

      it "does not call the human language detector if there is already a language" do
        article.language = "en"
        article.save

        expect(language_detector).not_to have_received(:detect)
      end
    end

    describe "slack notifications" do
      before do
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: SlackBotPingWorker)
      end

      it "notifies the proper slack channel about a recently published new article" do
        Timecop.freeze(Time.current) do
          article = create(:article, published: true)

          url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"
          message = "New Article Published: #{article.title}\n#{url}#{article.path}"
          args = {
            message: message,
            channel: "activity",
            username: "article_bot",
            icon_emoji: ":writing_hand:"
          }.stringify_keys

          sidekiq_assert_enqueued_jobs(1, only: SlackBotPingWorker)
          job = sidekiq_enqueued_jobs(worker: SlackBotPingWorker).last
          expect(job["args"]).to eq([args])
        end
      end

      it "does not send a notification for a new article published more than 30 seconds ago" do
        Timecop.freeze(Time.current) do
          sidekiq_assert_no_enqueued_jobs(only: SlackBotPingWorker) do
            create(:article, published: true, published_at: 31.seconds.ago)
          end
        end
      end

      it "does not send a notification for a non published article" do
        sidekiq_assert_no_enqueued_jobs(only: SlackBotPingWorker) do
          create(:article, published: false)
        end
      end

      it "sends a notification for a draft article that gets published" do
        Timecop.freeze(Time.current) do
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            article.update_columns(published: false)
            article.update(published: true, published_at: Time.current)
          end
        end
      end
    end
  end

  describe ".feed" do
    it "returns records with a subset of attributes" do
      feed_article = described_class.feed.first

      fields = %w[id tag_list published_at processed_html user_id organization_id title path]
      expect(feed_article.attributes.keys).to match_array(fields)
    end
  end

  describe "#touch_by_reaction" do
    it "reindexes elasticsearch doc" do
      sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: [described_class.to_s, article.search_id]) do
        article.touch_by_reaction
      end
    end
  end
end
