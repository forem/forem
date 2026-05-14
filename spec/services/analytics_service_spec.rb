require "rails_helper"

RSpec.describe AnalyticsService, type: :service do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article, user: user, published: true) }

  before do
    # We use Zonebie to fortify the code and spot time zone related problems but in this
    # particular case it can make these tests fail because,
    # for example, "2019-07-21T23:57:12-12:00" is the 22th in UTC, and since
    # the code delegates to DATE() in PostgreSQL which runs on UTC without time zone
    # info, there's no easy way for these tests to work correctly in a time zone on
    # the day line like "International Date Line West".
    # For this reason data created on "2019-07-21T23:57:12-12:00" will appear on the 22nd in the DB
    # and hence never be selected by the Analytics engine
    # In the meantime for a lack of a better solution, we force this tests to run at midday in UTC
    Timecop.freeze("2019-04-01T12:00:00Z")
  end

  after { Timecop.return }

  def format_date(datetime)
    # PostgreSQL DATE(..) function uses UTC.
    datetime.utc.to_date.iso8601
  end

  describe "initialization" do
    it "raises an error if start date is invalid" do
      expect { described_class.new(user, start_date: "2000-") }.to raise_error(ArgumentError)
    end

    it "raises an error if end date is invalid" do
      expect { described_class.new(user, end_date: "2000-") }.to raise_error(ArgumentError)
    end

    it "raises an error if an article does not belong to the user" do
      other_user = create(:user)
      article = create(:article, user: other_user)
      expect { described_class.new(user, article_id: article.id) }.to raise_error(ArgumentError)
    end

    it "clamps start_date to the owner's registration date when an earlier date is requested" do
      late_user = create(:user, registered_at: Time.zone.parse("2020-06-01"))
      service = described_class.new(late_user, start_date: "2015-01-01", end_date: "2020-06-30")
      # Weekly bucketing kicks in here (range > 180 days), so the first bucket
      # is the Monday of the week containing the registration date, not 2015.
      expect(service.grouped_by_day.keys.first).to eq("2020-06-01")
    end

    it "leaves start_date unchanged when it is after the owner's registration" do
      early_user = create(:user, registered_at: Time.zone.parse("2018-01-01"))
      service = described_class.new(early_user, start_date: "2019-04-01", end_date: "2019-04-04")
      expect(service.grouped_by_day.keys.first).to eq("2019-04-01")
    end

    it "clamps to the article's published_at when article_id is set, ignoring the owner's registration" do
      # Real-world case: an article is cross-posted into an organization that
      # was created long after the article was published. The org-creation
      # floor would silently chop off every bit of activity from before the
      # org existed; the article's stats should reflect the article's own
      # lifetime instead. (Time is frozen at 2019-04-01 by the outer before
      # block, so we use dates relative to that anchor.)
      org = create(:organization)
      org.update_columns(created_at: Time.zone.parse("2019-03-27"))
      author = create(:user)
      create(:organization_membership, user: author, organization: org, type_of_user: "admin")
      article = create(
        :article,
        :past,
        user: author,
        organization: org,
        published: true,
        past_published_at: Time.zone.parse("2018-05-01"),
      )

      service = described_class.new(
        org,
        start_date: "2010-04-01",
        end_date: "2019-04-01",
        article_id: article.id,
      )

      # Floor is the article's published_at (2018-05-01), NOT the org's
      # created_at (2019-03-27). Range > 180 days so weekly bucketing snaps
      # the first bucket to the Monday of the publish week (2018-04-30).
      expect(service.grouped_by_day.keys.first).to eq("2018-04-30")
    end
  end

  describe "adaptive bucketing" do
    it "uses daily buckets when the range is within DAILY_HISTORY_DAYS" do
      service = described_class.new(user, start_date: "2019-04-01", end_date: "2019-04-04")
      expect(service.grouped_by_day.keys).to eq(%w[2019-04-01 2019-04-02 2019-04-03 2019-04-04])
    end

    it "uses weekly buckets for old data and daily buckets for the most recent DAILY_HISTORY_DAYS" do
      long_user = create(:user, registered_at: Time.zone.parse("2018-01-01"))
      Timecop.freeze("2020-04-01T12:00:00Z") do
        service = described_class.new(long_user, start_date: "2019-04-01", end_date: "2020-04-01")
        keys = service.grouped_by_day.keys
        # Older portion: weekly Mondays. Recent 180 days: daily.
        expect(keys.first).to eq("2019-04-01") # a Monday
        expect(keys).to include("2020-03-31") # daily bucket near the end
        # Buckets in the older portion should be 7 days apart.
        weekly_keys = keys.select { |k| Date.parse(k) < (Date.parse("2020-04-01") - 180) }
        gaps = weekly_keys.each_cons(2).map { |a, b| (Date.parse(b) - Date.parse(a)).to_i }
        expect(gaps).to all(eq(7))
      end
    end
  end

  describe "#totals" do
    let(:analytics_service) { described_class.new(user) }

    it "returns totals stats for comments, reactions, follows and page views" do
      totals = analytics_service.totals
      expect(totals.keys.to_set).to eq(%i[comments reactions follows page_views].to_set)
    end

    it "returns totals stats for an org" do
      totals = described_class.new(organization).totals
      expect(totals.keys.to_set).to eq(%i[comments reactions follows page_views].to_set)
    end

    describe "comments stats" do
      it "returns stats" do
        stats = analytics_service.totals[:comments]
        expect(stats.keys).to eq(%i[total])
      end

      it "returns the total number of comments" do
        create(:comment, commentable: article, score: 1)
        expected_stats = { total: 1 }
        expect(analytics_service.totals[:comments]).to eq(expected_stats)
      end

      it "returns zero as total if there are no scored comments" do
        create(:comment, commentable: article, score: 0)
        expected_stats = { total: 0 }
        expect(analytics_service.totals[:comments]).to eq(expected_stats)
      end
    end

    describe "reactions stats" do
      before { Reaction.where(reactable: article).delete_all }

      it "returns stats" do
        stats = described_class.new(user).totals[:reactions]
        expect(stats.keys).to eq(%i[total like readinglist unicorn exploding_head raised_hands fire unique_reactors])
      end

      it "returns the total number of reactions" do
        create(:reaction, reactable: article)
        expect(analytics_service.totals[:reactions][:total]).to eq(1)
      end

      it "returns zero as total if there are no public category reactions" do
        reaction = create(:reaction, reactable: article)
        reaction.update_columns(category: "thumbsdown")
        expect(analytics_service.totals[:reactions][:total]).to eq(0)
      end

      it "returns the number of like reactions" do
        create(:reaction, reactable: article, category: :like)
        expect(analytics_service.totals[:reactions][:like]).to eq(1)
      end

      it "returns zero as the number of like reactions" do
        create(:reaction, reactable: article, category: :unicorn)
        expect(analytics_service.totals[:reactions][:like]).to eq(0)
      end

      it "returns the number of readinglist reactions" do
        create(:reaction, reactable: article, category: :readinglist)
        expect(analytics_service.totals[:reactions][:readinglist]).to eq(1)
      end

      it "returns zero as the number of readinglist reactions" do
        create(:reaction, reactable: article, category: :unicorn)
        expect(analytics_service.totals[:reactions][:readinglist]).to eq(0)
      end

      it "returns the number of unicorn reactions" do
        create(:reaction, reactable: article, category: :unicorn)
        expect(analytics_service.totals[:reactions][:unicorn]).to eq(1)
      end

      it "returns zero as the number of unicorn reactions" do
        create(:reaction, reactable: article, category: :like)
        expect(analytics_service.totals[:reactions][:unicorn]).to eq(0)
      end

      it "returns the number of exploding_head reactions" do
        create(:reaction, reactable: article, category: :exploding_head)
        expect(analytics_service.totals[:reactions][:exploding_head]).to eq(1)
      end

      it "returns the number of raised_hands reactions" do
        create(:reaction, reactable: article, category: :raised_hands)
        expect(analytics_service.totals[:reactions][:raised_hands]).to eq(1)
      end

      it "returns the number of fire reactions" do
        create(:reaction, reactable: article, category: :fire)
        expect(analytics_service.totals[:reactions][:fire]).to eq(1)
      end

      it "returns the number of unique reactors" do
        user2 = create(:user)
        create(:reaction, reactable: article, category: :like, user: user)
        create(:reaction, reactable: article, category: :unicorn, user: user)
        create(:reaction, reactable: article, category: :like, user: user2)
        expect(analytics_service.totals[:reactions][:unique_reactors]).to eq(2)
      end

      it "returns zero unique reactors when there are no reactions" do
        expect(analytics_service.totals[:reactions][:unique_reactors]).to eq(0)
      end
    end

    describe "follows stats" do
      it "returns stats" do
        stats = analytics_service.totals[:follows]
        expect(stats.keys).to eq(%i[total])
      end

      it "returns the total number of follows" do
        create(:follow, followable: user)
        expected_stats = { total: 1 }
        expect(analytics_service.totals[:follows]).to eq(expected_stats)
      end

      it "returns zero as total if there are no follows" do
        expected_stats = { total: 0 }
        expect(analytics_service.totals[:follows]).to eq(expected_stats)
      end
    end

    describe "page views stats" do
      it "returns stats" do
        stats = analytics_service.totals[:page_views]
        expect(stats.keys).to eq(%i[total average_read_time_in_seconds total_read_time_in_seconds])
      end

      it "returns the total number of page views from page_views_count" do
        article.update_columns(page_views_count: 1)
        expect(analytics_service.totals[:page_views][:total]).to eq(1)
      end

      it "returns zero as total if there are no page views" do
        expect(analytics_service.totals[:page_views][:total]).to eq(0)
      end

      it "returns the average read time in seconds" do
        create(:page_view, user: user, article: article, time_tracked_in_seconds: 15)
        create(:page_view, user: user, article: article, time_tracked_in_seconds: 45)
        expect(analytics_service.totals[:page_views][:average_read_time_in_seconds]).to eq(30)
      end

      it "returns zero as the average read time in seconds without views" do
        expect(analytics_service.totals[:page_views][:average_read_time_in_seconds]).to eq(0)
      end

      it "returns the total read time in seconds" do
        article.update_columns(page_views_count: 1)
        create(:page_view, user: user, article: article, time_tracked_in_seconds: 15)
        create(:page_view, user: user, article: article, time_tracked_in_seconds: 45)
        # average read time * total_views
        expect(analytics_service.totals[:page_views][:total_read_time_in_seconds]).to eq(30)
      end

      it "returns zero as the total read time in seconds with no page views" do
        expect(analytics_service.totals[:page_views][:total_read_time_in_seconds]).to eq(0)
      end
    end
  end

  describe "#grouped_by_day" do
    it "returns stats grouped by day" do
      stats = described_class.new(
        user, start_date: "2019-04-01", end_date: "2019-04-04"
      ).grouped_by_day
      expect(stats.keys).to eq(%w[2019-04-01 2019-04-02 2019-04-03 2019-04-04])
    end

    it "returns stats for comments, reactions, follows and page views for a specific day" do
      stats = described_class.new(user, start_date: "2019-04-01").grouped_by_day
      expect(stats["2019-04-01"].keys.to_set).to eq(%i[comments reactions page_views follows].to_set)
    end

    it "returns stats for an org" do
      stats = described_class.new(
        organization, start_date: "2019-04-01", end_date: "2019-04-04"
      ).grouped_by_day
      expect(stats.keys).to eq(%w[2019-04-01 2019-04-02 2019-04-03 2019-04-04])
      expect(stats["2019-04-01"].keys.to_set).to eq(%i[comments reactions page_views follows].to_set)
    end

    describe "comments stats on a specific day" do
      it "returns stats" do
        analytics_service = described_class.new(user, start_date: "2019-04-01", end_date: "2019-04-04")
        stats = analytics_service.grouped_by_day["2019-04-01"][:comments]
        expect(stats.keys).to eq(%i[total])
      end

      it "returns the total number of comments" do
        comment = create(:comment, commentable: article, score: 1)
        expected_stats = { total: 1 }
        date = format_date(comment.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:comments]).to eq(expected_stats)
      end

      it "returns zero as total if there are no scored comments" do
        comment = create(:comment, commentable: article, score: 0)
        expected_stats = { total: 0 }
        date = format_date(comment.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:comments]).to eq(expected_stats)
      end
    end

    describe "reactions stats on a specific day" do
      before { Reaction.where(reactable: article).delete_all }

      it "returns stats" do
        analytics_service = described_class.new(user, start_date: "2019-04-01")
        stats = analytics_service.grouped_by_day["2019-04-01"][:reactions]
        expect(stats.keys).to eq(%i[total like readinglist unicorn exploding_head raised_hands fire unique_reactors])
      end

      it "returns the total number of reactions" do
        reaction = create(:reaction, reactable: article)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:total]).to eq(1)
      end

      it "returns zero as total if there are no public category reactions" do
        reaction = create(:reaction, reactable: article)
        reaction.update_columns(category: "thumbsdown")
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:total]).to eq(0)
      end

      it "returns the number of like reactions" do
        reaction = create(:reaction, reactable: article, category: :like)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:like]).to eq(1)
      end

      it "returns zero as the number of like reactions" do
        reaction = create(:reaction, reactable: article, category: :unicorn)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:like]).to eq(0)
      end

      it "returns the number of readinglist reactions" do
        reaction = create(:reaction, reactable: article, category: :readinglist)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:readinglist]).to eq(1)
      end

      it "returns zero as the number of readinglist reactions" do
        reaction = create(:reaction, reactable: article, category: :unicorn)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:readinglist]).to eq(0)
      end

      it "returns the number of unicorn reactions" do
        reaction = create(:reaction, reactable: article, category: :unicorn)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:unicorn]).to eq(1)
      end

      it "returns zero as the number of unicorn reactions" do
        reaction = create(:reaction, reactable: article, category: :like)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:unicorn]).to eq(0)
      end

      it "returns unique reactors per day" do
        user2 = create(:user)
        create(:reaction, reactable: article, category: :like, user: user)
        reaction = create(:reaction, reactable: article, category: :unicorn, user: user)
        create(:reaction, reactable: article, category: :like, user: user2)
        date = format_date(reaction.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:reactions][:unique_reactors]).to eq(2)
      end
    end

    describe "follows stats for a specific day" do
      it "returns stats" do
        analytics_service = described_class.new(user, start_date: "2019-04-01")
        stats = analytics_service.grouped_by_day["2019-04-01"][:follows]
        expect(stats.keys).to eq(%i[total])
      end

      it "returns the total number of follows" do
        follow = create(:follow, followable: user)
        date = format_date(follow.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expected_stats = { total: 1 }
        expect(analytics_service.grouped_by_day[date][:follows]).to eq(expected_stats)
      end

      it "returns zero as total if there are no follows" do
        date = format_date(Time.current)
        analytics_service = described_class.new(user, start_date: date)
        expected_stats = { total: 0 }
        expect(analytics_service.grouped_by_day[date][:follows]).to eq(expected_stats)
      end
    end

    describe "page views stats for a specific day" do
      before { PageView.where(article: article).delete_all }

      it "returns stats" do
        analytics_service = described_class.new(user, start_date: "2019-04-01")
        stats = analytics_service.grouped_by_day["2019-04-01"][:page_views]
        expect(stats.keys).to eq(%i[total average_read_time_in_seconds total_read_time_in_seconds])
      end

      it "returns the total number of page views from counts_for_number_of_views" do
        pv = create(:page_view, user: user, article: article, counts_for_number_of_views: 5)
        date = format_date(pv.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:page_views][:total]).to eq(5)
      end

      it "returns zero as total if there are no page views" do
        date = format_date(Time.current)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:page_views][:total]).to eq(0)
      end

      it "returns the average read time in seconds" do
        create(:page_view, user: user, article: article, time_tracked_in_seconds: 15)
        pv = create(:page_view, user: user, article: article, time_tracked_in_seconds: 45)
        date = format_date(pv.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][
          :page_views][:average_read_time_in_seconds]).to eq(30)
      end

      it "returns zero as the average read time in seconds without views" do
        date = format_date(Time.current)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][
          :page_views][:average_read_time_in_seconds]).to eq(0)
      end

      it "returns the total read time in seconds" do
        create(:page_view, user: user, article: article, time_tracked_in_seconds: 15)
        create(:page_view, user: user, article: article, time_tracked_in_seconds: 45)
        date = format_date(article.created_at)
        analytics_service = described_class.new(user, start_date: date)
        # average read time (30) * total_views (2)
        expect(analytics_service.grouped_by_day[date][
          :page_views][:total_read_time_in_seconds]).to eq(60)
      end

      it "returns zero as the total read time in seconds with no page views" do
        date = format_date(Time.current)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][
          :page_views][:total_read_time_in_seconds]).to eq(0)
      end

      it "works correctly if the page views contain nil in time_tracked_in_seconds" do
        create(:page_view, user: user, article: article, time_tracked_in_seconds: nil)
        create(:page_view, user: user, article: article, time_tracked_in_seconds: nil)
        date = format_date(article.created_at)
        analytics_service = described_class.new(user, start_date: date)
        expect(analytics_service.grouped_by_day[date][:page_views][:total]).to eq(2)
        expect(analytics_service.grouped_by_day[date][:page_views][:average_read_time_in_seconds]).to eq(0)
        expect(analytics_service.grouped_by_day[date][:page_views][:total_read_time_in_seconds]).to eq(0)
      end
    end
  end

  describe "#referrers" do
    let(:analytics_service) { described_class.new(user) }

    context "when working on domains" do
      before { PageView.where(article: article).delete_all }

      it "returns unique domains with a count" do
        url = Faker::Internet.url
        create(:page_view, user: user, article: article, referrer: url)
        create(:page_view, user: user, article: article, referrer: url)
        domains = analytics_service.referrers[:domains]
        expect(domains.first).to eq(domain: Addressable::URI.parse(url).domain, count: 2)
      end

      it "returns unique domains with a count when there is a date range" do
        url = Faker::Internet.url
        create(:page_view, user: user, article: article, referrer: url)
        create(:page_view, user: user, article: article, referrer: url)
        date = format_date(article.created_at)
        analytics_service = described_class.new(user, start_date: date)
        domains = analytics_service.referrers[:domains]
        expect(domains.first).to eq(domain: Addressable::URI.parse(url).domain, count: 2)
      end

      it "returns nothing if there is no data" do
        expect(analytics_service.referrers[:domains]).to be_empty
      end

      it "returns the domains ordered by number of views" do
        other_url = Faker::Internet.url
        create_list(:page_view, 2, user: user, article: article, referrer: other_url)
        top_url = Faker::Internet.url
        create_list(:page_view, 3, user: user, article: article, referrer: top_url, counts_for_number_of_views: 10)

        expected_result = [
          { domain: Addressable::URI.parse(top_url).domain, count: 30 },
          { domain: Addressable::URI.parse(other_url).domain, count: 2 },
        ]
        expect(analytics_service.referrers[:domains]).to eq(expected_result)
      end

      it "returns 20 domains at most by default" do
        21.times do |n|
          create(:page_view, user: user, article: article, referrer: "http://fakeurl#{n}.com")
        end
        expect(analytics_service.referrers[:domains].size).to eq(20)
      end

      it "returns the most visited domain if asked for only one result" do
        top_url = Faker::Internet.url
        create_list(:page_view, 3, user: user, article: article, referrer: top_url)
        # Faker url's generate colliding domain names about 1 to two times in 10,000
        # Faker domains never end in ".dev" so this is a safe choice
        other_url = Faker::Internet.url(host: "forem.dev")
        create_list(:page_view, 2, user: user, article: article, referrer: other_url)

        top_domain = Addressable::URI.parse(top_url).domain
        result = analytics_service.referrers(top: 1)[:domains]
        expect(result).to eq([{ domain: top_domain, count: 3 }])
      end
    end
  end

  describe "#top_contributors" do
    let(:analytics_service) { described_class.new(user) }
    let(:contributor) { create(:user) }

    it "returns an empty array when there are no articles" do
      other_user = create(:user)
      service = described_class.new(other_user)
      expect(service.top_contributors).to eq([])
    end

    it "excludes self-reactions from results" do
      create(:reaction, reactable: article, category: :like, user: user)
      expect(analytics_service.top_contributors).to eq([])
    end

    it "excludes readinglist reactions" do
      create(:reaction, reactable: article, category: :readinglist, user: contributor)
      expect(analytics_service.top_contributors).to eq([])
    end

    it "includes non-readinglist reactions from other users" do
      create(:reaction, reactable: article, category: :like, user: contributor)
      result = analytics_service.top_contributors
      expect(result.length).to eq(1)
      expect(result.first[:username]).to eq(contributor.username)
      expect(result.first[:reactions_count]).to eq(1)
      expect(result.first[:comments_count]).to eq(0)
      expect(result.first[:score]).to eq(1)
    end

    it "weights comments at 6x" do
      create(:comment, commentable: article, user: contributor, score: 1)
      result = analytics_service.top_contributors
      expect(result.first[:comments_count]).to eq(1)
      expect(result.first[:score]).to eq(6)
    end

    it "excludes comments with score <= 0" do
      create(:comment, commentable: article, user: contributor, score: 0)
      expect(analytics_service.top_contributors).to eq([])
    end

    it "excludes self-comments" do
      create(:comment, commentable: article, user: user, score: 1)
      expect(analytics_service.top_contributors).to eq([])
    end

    it "combines reactions and comments for the same user" do
      create(:reaction, reactable: article, category: :like, user: contributor)
      create(:comment, commentable: article, user: contributor, score: 1)
      result = analytics_service.top_contributors
      expect(result.length).to eq(1)
      expect(result.first[:reactions_count]).to eq(1)
      expect(result.first[:comments_count]).to eq(1)
      expect(result.first[:score]).to eq(7) # 1 + 6
    end

    it "respects the limit parameter" do
      3.times { |i| create(:reaction, reactable: article, category: :like, user: create(:user)) }
      result = analytics_service.top_contributors(limit: 2)
      expect(result.length).to eq(2)
    end

    it "orders by score descending" do
      user_a = create(:user)
      user_b = create(:user)
      create(:reaction, reactable: article, category: :like, user: user_a)
      create(:comment, commentable: article, user: user_b, score: 1) # score 6
      result = analytics_service.top_contributors
      expect(result.first[:username]).to eq(user_b.username)
    end

    it "works with organization owner" do
      create(:organization_membership, user: user, organization: organization)
      org_article = create(:article, user: user, organization: organization, published: true)
      create(:reaction, reactable: org_article, category: :like, user: contributor)
      service = described_class.new(organization)
      result = service.top_contributors
      expect(result.length).to eq(1)
      expect(result.first[:username]).to eq(contributor.username)
    end

    it "returns profile data for each contributor" do
      create(:reaction, reactable: article, category: :like, user: contributor)
      result = analytics_service.top_contributors.first
      expect(result).to include(:user_id, :username, :name, :profile_image, :reactions_count, :comments_count, :score)
    end
  end

  describe "#follower_engagement" do
    let(:analytics_service) { described_class.new(user) }
    let(:follower) { create(:user) }

    before do
      create(:follow, follower: follower, followable: user, blocked: false)
    end

    it "returns zero ratio when user has no followers" do
      other_user = create(:user)
      create(:article, user: other_user, published: true)
      service = described_class.new(other_user)
      result = service.follower_engagement
      expect(result).to eq({ total_followers: 0, engaged_followers: 0, ratio: 0.0 })
    end

    it "returns zero engaged when follower has not interacted" do
      result = analytics_service.follower_engagement
      expect(result[:total_followers]).to eq(1)
      expect(result[:engaged_followers]).to eq(0)
      expect(result[:ratio]).to eq(0.0)
    end

    it "counts a follower who reacted" do
      create(:reaction, reactable: article, category: :like, user: follower)
      result = analytics_service.follower_engagement
      expect(result[:total_followers]).to eq(1)
      expect(result[:engaged_followers]).to eq(1)
      expect(result[:ratio]).to eq(100.0)
    end

    it "counts a follower who commented" do
      create(:comment, commentable: article, user: follower, score: 1)
      result = analytics_service.follower_engagement
      expect(result[:engaged_followers]).to eq(1)
    end

    it "counts a follower with both reaction and comment only once" do
      create(:reaction, reactable: article, category: :like, user: follower)
      create(:comment, commentable: article, user: follower, score: 1)
      result = analytics_service.follower_engagement
      expect(result[:engaged_followers]).to eq(1)
    end

    it "excludes readinglist reactions" do
      create(:reaction, reactable: article, category: :readinglist, user: follower)
      result = analytics_service.follower_engagement
      expect(result[:engaged_followers]).to eq(0)
    end

    it "excludes low-score comments" do
      create(:comment, commentable: article, user: follower, score: 0)
      result = analytics_service.follower_engagement
      expect(result[:engaged_followers]).to eq(0)
    end

    it "excludes blocked followers" do
      blocked_follower = create(:user)
      create(:follow, follower: blocked_follower, followable: user, blocked: true)
      create(:reaction, reactable: article, category: :like, user: blocked_follower)
      result = analytics_service.follower_engagement
      expect(result[:total_followers]).to eq(1) # only the non-blocked follower
    end

    it "does not count non-followers" do
      non_follower = create(:user)
      create(:reaction, reactable: article, category: :like, user: non_follower)
      result = analytics_service.follower_engagement
      expect(result[:engaged_followers]).to eq(0)
    end

    it "calculates correct ratio with multiple followers" do
      follower2 = create(:user)
      follower3 = create(:user)
      create(:follow, follower: follower2, followable: user, blocked: false)
      create(:follow, follower: follower3, followable: user, blocked: false)
      create(:reaction, reactable: article, category: :like, user: follower)
      result = analytics_service.follower_engagement
      expect(result[:total_followers]).to eq(3)
      expect(result[:engaged_followers]).to eq(1)
      expect(result[:ratio]).to eq(33.3)
    end

    it "works with organization owner" do
      create(:organization_membership, user: user, organization: organization)
      org_article = create(:article, user: user, organization: organization, published: true)
      org_follower = create(:user)
      create(:follow, follower: org_follower, followable: organization, blocked: false)
      create(:reaction, reactable: org_article, category: :like, user: org_follower)
      service = described_class.new(organization)
      result = service.follower_engagement
      expect(result[:total_followers]).to eq(1)
      expect(result[:engaged_followers]).to eq(1)
    end
  end
end
