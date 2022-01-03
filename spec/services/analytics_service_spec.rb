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
      expect(-> { described_class.new(user, start_date: "2000-") }).to raise_error(ArgumentError)
    end

    it "raises an error if end date is invalid" do
      expect(-> { described_class.new(user, end_date: "2000-") }).to raise_error(ArgumentError)
    end

    it "raises an error if an article does not belong to the user" do
      other_user = create(:user)
      article = create(:article, user: other_user)
      expect(-> { described_class.new(user, article_id: article.id) }).to raise_error(ArgumentError)
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
        expect(stats.keys).to eq(%i[total like readinglist unicorn])
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
        expect(stats.keys).to eq(%i[total like readinglist unicorn])
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
        other_url = Faker::Internet.url
        create_list(:page_view, 2, user: user, article: article, referrer: other_url)

        top_domain = Addressable::URI.parse(top_url).domain
        result = analytics_service.referrers(top: 1)[:domains]
        expect(result).to eq([{ domain: top_domain, count: 3 }])
      end
    end
  end
end
