require "rails_helper"

RSpec.describe Article, type: :model do
  def build_and_validate_article(*args)
    article = build(:article, *args)
    article.validate!
    article
  end

  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }

  include_examples "#sync_reactions_count", :article
  it_behaves_like "UserSubscriptionSourceable"

  describe "validations" do
    it { is_expected.to belong_to(:collection).optional }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to belong_to(:user) }

    it { is_expected.to have_one(:discussion_lock).dependent(:destroy) }

    it { is_expected.to have_many(:comments).dependent(:nullify) }
    it { is_expected.to have_many(:mentions).dependent(:destroy) }
    it { is_expected.to have_many(:html_variant_successes).dependent(:nullify) }
    it { is_expected.to have_many(:html_variant_trials).dependent(:nullify) }
    it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:notifications).dependent(:delete_all) }
    it { is_expected.to have_many(:page_views).dependent(:destroy) }
    it { is_expected.to have_many(:polls).dependent(:destroy) }
    it { is_expected.to have_many(:profile_pins).dependent(:destroy) }
    it { is_expected.to have_many(:rating_votes).dependent(:destroy) }
    it { is_expected.to have_many(:sourced_subscribers) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:tags) }
    it { is_expected.to have_many(:user_subscriptions).dependent(:nullify) }

    it { is_expected.to validate_length_of(:body_markdown).is_at_least(0) }
    it { is_expected.to validate_length_of(:cached_tag_list).is_at_most(126) }
    it { is_expected.to validate_length_of(:title).is_at_most(128) }

    it { is_expected.to validate_presence_of(:boost_states) }
    it { is_expected.to validate_presence_of(:comments_count) }
    it { is_expected.to validate_presence_of(:positive_reactions_count) }
    it { is_expected.to validate_presence_of(:previous_public_reactions_count) }
    it { is_expected.to validate_presence_of(:public_reactions_count) }
    it { is_expected.to validate_presence_of(:rating_votes_count) }
    it { is_expected.to validate_presence_of(:reactions_count) }
    it { is_expected.to validate_presence_of(:user_subscriptions_count) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:user_id) }

    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:user_id) }

    it { is_expected.not_to allow_value("foo").for(:main_image_background_hex_color) }

    describe "::admin_published_with" do
      it "includes mascot-published articles" do
        allow(Settings::General).to receive(:mascot_user_id).and_return(3)
        user = create(:user, id: 3)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(1)
      end

      it "includes staff-user-published articles" do
        allow(Settings::Community).to receive(:staff_user_id).and_return(3)
        user = create(:user, id: 3)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(1)
      end

      it "includes admin published articles" do
        user = create(:user, :admin)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(1)
      end

      it "does not include regular user published articles" do
        user = create(:user)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(0)
      end
    end

    describe "#body_markdown" do
      it "is unique scoped for user_id and title", :aggregate_failures do
        art2 = build(:article, body_markdown: article.body_markdown, user: article.user, title: article.title)

        expect(art2).not_to be_valid
        expect(art2.errors_as_sentence).to match("markdown has already been taken")
      end

      # using https://unicode-table.com/en/11A15/ multibyte char
      it "is valid if its bytesize is less than 800 kilobytes" do
        article.body_markdown = "𑨕" * 204_800 # 4 bytes x 204800 = 800 kilobytes

        expect(article).to be_valid
      end

      it "is not valid if its bytesize exceeds 800 kilobytes" do
        article.body_markdown = "𑨕" * 204_801

        expect(article).not_to be_valid
        expect(article.errors_as_sentence).to match("too long")
      end
    end

    describe "#validate co_authors" do
      it "is invalid if the co_author is the same as the author" do
        article.co_author_ids = [user.id]

        expect(article).not_to be_valid
      end

      it "is invalid if there are duplicate co_authors for the same article" do
        co_author1 = create(:user)
        article.co_author_ids = [co_author1, co_author1]

        expect(article).not_to be_valid
      end

      it "is invalid if the co_author is entered as a text value rather than an integer" do
        article.co_author_ids = [user.id, "abc"]

        expect(article).not_to be_valid
      end

      it "is invalid if the co_author ID is not greater than 0" do
        article.co_author_ids = [user.id, 0]

        expect(article).not_to be_valid
      end

      it "is valid if co_author_ids is nil" do
        article.co_author_ids = nil

        expect(article).to be_valid
      end
    end

    context "when published" do
      before do
        # rubocop:disable RSpec/NamedSubject
        allow(subject).to receive(:published?).and_return(true) # rubocop:disable RSpec/SubjectStub
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
        message = "must not have spaces"

        expect(article).not_to be_valid
        expect(article.errors.messages[:canonical_url]).to include(message)
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
      xit "is not valid if it contains invalid liquid tags" do
        body = "{% github /thepracticaldev/dev.to %}"
        article = build(:article, body_markdown: body)
        expect(article).not_to be_valid
        expect(article.errors[:base].first).to match(/Invalid GitHub/)
      end

      it "is valid with valid liquid tags", :vcr do
        VCR.use_cassette("twitter_client_status_extended") do
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

      it "rejects tag with non-alphanumerics" do
        expect { build(:article, tags: "c++").validate! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "always downcase tags" do
        tags = "UPPERCASE, CAPITALIZE"
        article = create(:article, tags: tags)
        expect(article.tag_list).to eq(tags.downcase.split(", "))
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
      unpublished_article = build(:article, published: false, published_at: nil)
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
        article.update(body_markdown: "#{body}s")
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
      expect(article.readable_publish_date).to eq(time_now.strftime("%b %-e"))
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

  describe ".active_help" do
    it "returns properly filtered articles under the 'help' tag" do
      filtered_article = create(:article, user: user, tags: "help",
                                          published_at: 13.hours.ago, comments_count: 5, score: -3)
      articles = described_class.active_help
      expect(articles).to include(filtered_article)
    end

    it "returns any published articles tagged with 'help' when there are no articles that fit the criteria" do
      unfiltered_article = create(:article, user: user, tags: "help",
                                            published_at: 10.hours.ago, comments_count: 8, score: -5)
      articles = described_class.active_help
      expect(articles).to include(unfiltered_article)
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

  describe ".search_optimized_title_preamble" do
    let!(:top_article) do
      create(:article, search_optimized_title_preamble: "Hello #{rand(1000)}", tags: "good, greatalicious")
    end

    it "returns article with title preamble" do
      articles = described_class.search_optimized
      expect(articles.first[0]).to eq(top_article.path)
      expect(articles.first[1]).to eq(top_article.search_optimized_title_preamble)
    end

    it "does not return article without preamble" do
      articles = described_class.search_optimized
      new_article = create(:article)
      expect(articles.flatten).not_to include(new_article.path)
    end

    it "does return multiple articles with preamble ordered by updated_at" do
      new_article = create(:article, search_optimized_title_preamble: "Testerino")
      articles = described_class.search_optimized
      expect(articles.first[1]).to eq(new_article.search_optimized_title_preamble)
      expect(articles.second[1]).to eq(top_article.search_optimized_title_preamble)
    end

    it "returns articles ordered by organic_page_views_count by tag" do
      articles = described_class.search_optimized("greatalicious")
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns nothing if no tagged articles" do
      articles = described_class.search_optimized("godsdsdsdsgoo")
      expect(articles).to be_empty
    end
  end

  describe ".cached_tagged_with" do
    it "can search for a single tag" do
      included = create(:article, tags: "includeme")
      excluded = create(:article, tags: "lol, nope")

      articles = described_class.cached_tagged_with("includeme")

      expect(articles).to include included
      expect(articles).not_to include excluded
      expect(articles.to_a).to eq described_class.tagged_with("includeme").to_a
    end

    it "can search for a single tag when given a symbol" do
      included = create(:article, tags: "includeme")
      excluded = create(:article, tags: "lol, nope")

      articles = described_class.cached_tagged_with(:includeme)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded)
      expect(articles.to_a).to eq(described_class.tagged_with("includeme").to_a)
    end

    it "can search for a single tag when given a Tag object" do
      included = create(:article, tags: "includeme")
      excluded = create(:article, tags: "lol, nope")

      tag = Tag.find_by(name: :includeme)

      articles = described_class.cached_tagged_with(tag)

      expect(articles).to include included
      expect(articles).not_to include excluded
      expect(articles.to_a).to eq described_class.tagged_with("includeme").to_a
    end

    it "can search among multiple tags" do
      included = [
        create(:article, tags: "omg, wtf"),
        create(:article, tags: "omg, lol"),
      ]
      excluded = create(:article, tags: "nope, excluded")

      articles = described_class.cached_tagged_with("omg")

      expect(articles).to include(*included)
      expect(articles).not_to include excluded
      expect(articles.to_a).to include(*described_class.tagged_with("omg").to_a)
    end

    it "can search for multiple tags" do
      included = create(:article, tags: "includeme, please, lol")
      excluded_partial_match = create(:article, tags: "excluded, please")
      excluded_no_match = create(:article, tags: "excluded, omg")

      articles = described_class.cached_tagged_with(%w[includeme please])

      expect(articles).to include included
      expect(articles).not_to include excluded_partial_match
      expect(articles).not_to include excluded_no_match
      expect(articles.to_a).to eq described_class.tagged_with(%w[includeme please]).to_a
    end

    it "can search for multiple tags passed as an array of symbols" do
      included = create(:article, tags: "includeme, please, lol")
      excluded_partial_match = create(:article, tags: "excluded, please")
      excluded_no_match = create(:article, tags: "excluded, omg")

      articles = described_class.cached_tagged_with(%i[includeme please])

      expect(articles).to include(included)
      expect(articles).not_to include(excluded_partial_match)
      expect(articles).not_to include(excluded_no_match)
      expect(articles.to_a).to eq(described_class.tagged_with(%i[includeme please]).to_a)
    end

    it "can search for multiple tags passed as an array of Tag objects" do
      included = create(:article, tags: "includeme, please, lol")
      excluded_partial_match = create(:article, tags: "excluded, please")
      excluded_no_match = create(:article, tags: "excluded, omg")

      tags = Tag.where(name: %i[includeme please]).to_a
      articles = described_class.cached_tagged_with(tags)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded_partial_match)
      expect(articles).not_to include(excluded_no_match)
      expect(articles.to_a).to eq(described_class.tagged_with(%i[includeme please]).to_a)
    end
  end

  describe ".cached_tagged_with_any" do
    it "can search for a single tag" do
      included = create(:article, tags: "includeme")
      excluded = create(:article, tags: "lol, nope")

      articles = described_class.cached_tagged_with_any("includeme")

      expect(articles).to include included
      expect(articles).not_to include excluded
      expect(articles.to_a).to eq described_class.tagged_with("includeme", any: true).to_a
    end

    it "can search for a single tag when given a symbol" do
      included = create(:article, tags: "includeme")
      excluded = create(:article, tags: "lol, nope")

      articles = described_class.cached_tagged_with_any(:includeme)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded)
      expect(articles.to_a).to eq(described_class.tagged_with("includeme", any: true).to_a)
    end

    it "can search for a single tag when given a Tag object" do
      included = create(:article, tags: "includeme")
      excluded = create(:article, tags: "lol, nope")

      tag = Tag.find_by(name: :includeme)
      articles = described_class.cached_tagged_with_any(tag)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded)
      expect(articles.to_a).to eq(described_class.tagged_with("includeme", any: true).to_a)
    end

    it "can search among multiple tags" do
      included = [
        create(:article, tags: "omg, wtf"),
        create(:article, tags: "omg, lol"),
      ]
      excluded = create(:article, tags: "nope, excluded")

      articles = described_class.cached_tagged_with_any("omg")
      expected = described_class.tagged_with("omg", any: true).to_a

      expect(articles).to include(*included)
      expect(articles).not_to include excluded
      expect(articles.to_a).to include(*expected)
    end

    it "can search for multiple tags" do
      included = create(:article, tags: "includeme, please, lol")
      included_partial_match = create(:article, tags: "includeme, omg")
      excluded_no_match = create(:article, tags: "excluded, omg")

      articles = described_class.cached_tagged_with_any(%w[includeme please])
      expected = described_class.tagged_with(%w[includeme please], any: true).to_a

      expect(articles).to include included
      expect(articles).to include included_partial_match
      expect(articles).not_to include excluded_no_match

      expect(articles.to_a).to include(*expected)
    end

    it "can search for multiple tags when given an array of symbols" do
      included = create(:article, tags: "includeme, please, lol")
      included_partial_match = create(:article, tags: "includeme, omg")
      excluded_no_match = create(:article, tags: "excluded, omg")

      articles = described_class.cached_tagged_with_any(%i[includeme please])
      expected = described_class.tagged_with(%i[includeme please], any: true).to_a

      expect(articles).to include(included)
      expect(articles).to include(included_partial_match)
      expect(articles).not_to include(excluded_no_match)

      expect(articles.to_a).to include(*expected)
    end

    it "can search for multiple tags when given an array of Tag objects" do
      included = create(:article, tags: "includeme, please, lol")
      included_partial_match = create(:article, tags: "includeme, omg")
      excluded_no_match = create(:article, tags: "excluded, omg")

      tags = Tag.where(name: %i[includeme please]).to_a
      articles = described_class.cached_tagged_with_any(tags)
      expected = described_class.tagged_with(%i[includeme please], any: true).to_a

      expect(articles).to include(included)
      expect(articles).to include(included_partial_match)
      expect(articles).not_to include(excluded_no_match)

      expect(articles.to_a).to include(*expected)
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
    end

    it "assigns cached_organization on save" do
      article = create(:article, user: user, organization: create(:organization))
      expect(article.cached_organization.name).to eq(article.organization.name)
      expect(article.cached_organization.username).to eq(article.organization.username)
      expect(article.cached_organization.slug).to eq(article.organization.slug)
      expect(article.cached_organization.profile_image_90).to eq(article.organization.profile_image_90)
      expect(article.cached_organization.profile_image_url).to eq(article.organization.profile_image_url)
    end
  end

  context "when callbacks are triggered after create" do
    describe "detect animated images" do
      it "does not enqueue Articles::DetectAnimatedImagesWorker if the feature :detect_animated_images is disabled" do
        allow(FeatureFlag).to receive(:enabled?).with(:detect_animated_images).and_return(false)

        sidekiq_assert_no_enqueued_jobs(only: Articles::DetectAnimatedImagesWorker) do
          build(:article).save
        end
      end

      it "enqueues Articles::DetectAnimatedImagesWorker if the feature :detect_animated_images is enabled" do
        allow(FeatureFlag).to receive(:enabled?).with(:detect_animated_images).and_return(true)
        sidekiq_assert_enqueued_jobs(1, only: Articles::DetectAnimatedImagesWorker) do
          build(:article).save
        end
      end
    end
  end

  context "when callbacks are triggered after save" do
    describe "article path sanitizing" do
      it "returns a downcased username when user has uppercase characters" do
        upcased_user = create(:user, username: "UpcasedUserName")
        upcased_article = create(:article, user: upcased_user)
        expect(upcased_article.path).not_to match(/[AZ]+/)
      end

      it "returns a downcased username when an org slug has uppercase characters" do
        upcased_org = create(:organization, slug: "UpcasedSlug")
        upcased_article = create(:article, organization: upcased_org)
        expect(upcased_article.path).not_to match(/[AZ]+/)
      end
    end

    describe "spam" do
      before do
        allow(Settings::General).to receive(:mascot_user_id).and_return(user.id)
        allow(Settings::RateLimit).to receive(:spam_trigger_terms).and_return(
          ["yahoomagoo gogo", "testtestetest", "magoo.+magee"],
        )
      end

      it "creates vomit reaction if possible spam" do
        article.body_markdown = article.body_markdown.gsub(article.title, "This post is about Yahoomagoo gogo")
        article.save
        expect(Reaction.last.category).to eq("vomit")
        expect(Reaction.last.user_id).to eq(user.id)
      end

      it "creates vomit reaction if possible spam based on pattern" do
        article.body_markdown = article.body_markdown.gsub(article.title, "This post is about magoo to the magee")
        article.save
        expect(Reaction.last.category).to eq("vomit")
        expect(Reaction.last.user_id).to eq(user.id)
      end

      it "does not suspend user if only single vomit" do
        article.body_markdown = article.body_markdown.gsub(article.title, "This post is about Yahoomagoo gogo")
        article.save
        expect(article.user.suspended?).to be false
      end

      it "suspends user with 3 comment vomits" do
        second_article = create(:article, user: article.user)
        third_article = create(:article, user: article.user)
        article.body_markdown = article.body_markdown.gsub(article.title, "This post is about Yahoomagoo gogo")
        second_article.body_markdown = second_article.body_markdown.gsub(second_article.title, "testtestetest")
        third_article.body_markdown = third_article.body_markdown.gsub(third_article.title, "yahoomagoo gogo")

        article.save
        second_article.save
        third_article.save
        expect(article.user.suspended?).to be true
        expect(Note.last.reason).to eq "automatic_suspend"
      end

      it "does not create vomit reaction if does not have matching title" do
        article.save
        expect(Reaction.last).to be nil
      end

      it "does not create vomit reaction if does not have pattern match" do
        article.body_markdown = article.body_markdown.gsub(article.title, "This post is about magoo to")
        article.save
        expect(Reaction.last).to be nil
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

    describe "slack messages" do
      before do
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: Slack::Messengers::Worker)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          article.update(published: true, published_at: Time.current)
        end
      end

      it "does not queue a message for an article published more than 30 seconds ago" do
        Timecop.freeze(Time.current) do
          sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
            article.update(published: true, published_at: 31.seconds.ago)
          end
        end
      end

      it "does not queue a message for a draft article" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          article.update(body_markdown: "foobar", published: false)
        end
      end

      it "queues a message for a draft article that gets published" do
        Timecop.freeze(Time.current) do
          sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
            article.update_columns(published: false)
            article.update(published: true, published_at: Time.current)
          end
        end
      end
    end

    describe "detect animated images" do
      it "does not enqueue Articles::DetectAnimatedImagesWorker if the feature :detect_animated_images is disabled" do
        allow(FeatureFlag).to receive(:enabled?).with(:detect_animated_images).and_return(false)

        sidekiq_assert_no_enqueued_jobs(only: Articles::DetectAnimatedImagesWorker) do
          article.update(body_markdown: "a body")
        end
      end

      it "enqueues Articles::DetectAnimatedImagesWorker if the HTML has changed" do
        allow(FeatureFlag).to receive(:enabled?).with(:detect_animated_images).and_return(true)

        sidekiq_assert_enqueued_with(job: Articles::DetectAnimatedImagesWorker, args: [article.id]) do
          article.update(body_markdown: "a body")
        end
      end

      it "does not Articles::DetectAnimatedImagesWorker if the HTML does not change" do
        allow(FeatureFlag).to receive(:enabled?).with(:detect_animated_images).and_return(true)

        sidekiq_assert_no_enqueued_jobs(only: Articles::DetectAnimatedImagesWorker) do
          article.update(tag_list: %w[fsharp go])
        end
      end
    end
  end

  context "when triggers are invoked" do
    let(:article) { create(:article) }

    before do
      article.update(body_markdown: "An intense movie")
    end

    it "sets .reading_list_document on insert" do
      expect(article.reload.reading_list_document).to be_present
    end

    it "updates .reading_list_document with body_markdown" do
      article.update(body_markdown: "Something has changed")

      expect(article.reload.reading_list_document).to include("something")
    end

    it "updates .reading_list_document with cached_tag_list" do
      article.update(tag_list: %w[rust python])

      expect(article.reload.reading_list_document).to include("rust")
    end

    it "updates .reading_list_document with title" do
      article.update(title: "Synecdoche, Los Angeles")

      expect(article.reload.reading_list_document).to include("angeles")
    end

    it "removes a previous value from .reading_list_document on update", :aggregate_failures do
      tag = article.tags.first.name
      article.update(tag_list: %w[fsharp go])

      expect(article.reload.reading_list_document).not_to include(tag)
      expect(article.reload.reading_list_document).to include("fsharp")
    end
  end

  describe ".feed" do
    it "returns records with a subset of attributes" do
      feed_article = described_class.feed.first

      fields = %w[id tag_list published_at processed_html user_id organization_id title path cached_tag_list]
      expect(feed_article.attributes.keys).to match_array(fields)
    end
  end

  describe "#top_comments" do
    context "when article has comments" do
      let(:root_comment) { create(:comment, commentable: article, score: 20) }
      let(:child_comment) { create(:comment, commentable: article, score: 20, parent: root_comment) }
      let(:hidden_comment) { create(:comment, commentable: article, score: 20, hidden_by_commentable_user: true) }
      let(:deleted_comment) { create(:comment, commentable: article, score: 20, deleted: true) }

      before do
        root_comment
        child_comment
        hidden_comment
        deleted_comment
        create_list(:comment, 2, commentable: article, score: 20)
        article.reload
      end

      it "returns comments with score greater than 10" do
        expect(article.top_comments.first.score).to be > 10
      end

      it "only includes root comments" do
        expect(article.top_comments).not_to include(child_comment)
      end

      it "doesn't include hidden comments" do
        expect(article.top_comments).not_to include(hidden_comment)
      end

      it "doesn't include deleted comments" do
        expect(article.top_comments).not_to include(deleted_comment)
      end
    end

    context "when article does not have any comments" do
      it "retrns empty set if there aren't any top comments" do
        expect(article.top_comments).to be_empty
      end
    end
  end

  describe "co_author_ids_list=" do
    it "correctly sets co author ids from a comma separated list of ids" do
      co_author1 = create(:user)
      co_author2 = create(:user)
      article.co_author_ids_list = "#{co_author1.id}, #{co_author2.id}"
      expect(article.co_author_ids).to match_array([co_author1.id, co_author2.id])
    end
  end

  describe "#plain_html" do
    let(:body_markdown) do
      <<~MD
        ---
        title: Test highlight panel
        published: false
        ---

        text before

          ```ruby
          def foo():
            puts "bar"
          ```

        text after
      MD
    end

    it "doesn't include highlight panel markup" do
      article = create(:article, body_markdown: body_markdown)

      expect(article.plain_html).to include("text before")
      expect(article.plain_html).to include("highlight")
      expect(article.plain_html).not_to include("highlight__panel")
    end
  end

  describe "#user_mentions_in_markdown" do
    before do
      stub_const("Article::MAX_USER_MENTION_LIVE_AT", 1.day.ago) # Set live_at date to a time in the past
    end

    it "is valid with any number of mentions if created before MAX_USER_MENTION_LIVE_AT date" do
      # Explicitly set created_at date to a time before MAX_USER_MENTION_LIVE_AT
      article = create(:article, created_at: 3.days.ago)

      article.body_markdown = "hi @#{user.username}! " * (Settings::RateLimit.mention_creation + 1)
      expect(article).to be_valid
    end

    it "is valid with seven or fewer mentions if created after MAX_USER_MENTION_LIVE_AT date" do
      article.body_markdown = "hi @#{user.username}! " * Settings::RateLimit.mention_creation
      expect(article).to be_valid
    end

    it "is invalid with more than seven mentions if created after MAX_USER_MENTION_LIVE_AT date" do
      article.body_markdown = "hi @#{user.username}! " * (Settings::RateLimit.mention_creation + 1)
      expect(article).not_to be_valid
      expect(article.errors[:base])
        .to include("You cannot mention more than #{Settings::RateLimit.mention_creation} users in a post!")
    end
  end

  describe "#followers" do
    it "returns an array of users who follow the article's author" do
      following_user = create(:user)
      following_user.follow(user)

      expect(article.followers.length).to eq(1)
      expect(article.followers.first.username).to eq(following_user.username)
    end
  end

  describe "#update_score" do
    it "stably sets the correct blackbox values" do
      create(:reaction, reactable: article, points: 1)

      article.update_score
      expect { article.update_score }.not_to change { article.reload.hotness_score }
    end
  end

  describe "#feed_source_url and canonical_url must be unique for published articles" do
    let(:url) { "http://www.example.com" }

    it "is valid when both articles are drafts" do
      body_markdown = "---\ntitle: Title\npublished: false\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)

      expect(another_article).to be_valid
    end

    it "is valid when first article is a draft, second is published" do
      body_markdown = "---\ntitle: Title\npublished: false\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      body_markdown = "---\ntitle: Title\npublished: true\ncanonical_url: #{url}\n---\n\n"
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)

      expect(another_article).to be_valid
    end

    it "is valid when first article is published, second is draft" do
      body_markdown = "---\ntitle: Title\npublished: true\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      body_markdown = "---\ntitle: Title\npublished: false\ncanonical_url: #{url}\n---\n\n"
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)

      expect(another_article).to be_valid
    end

    it "is not valid when both articles are published" do
      body_markdown = "---\ntitle: Title\npublished: true\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)
      error_message = "has already been taken. " \
                      "Email #{ForemInstance.email} for further details."
      expect(another_article).not_to be_valid
      expect(another_article.errors.messages[:canonical_url]).to include(error_message)
      expect(another_article.errors.messages[:feed_source_url]).to include(error_message)
    end
  end
end
