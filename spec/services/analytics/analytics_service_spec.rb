require "rails_helper"

RSpec.describe AnalyticsService, type: :service do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article, user: user, published: true) }

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
      expect(totals.keys).to eq(%i[comments reactions follows page_views])
    end

    describe "comments stats" do
      it "returns stats" do
        stats = described_class.new(user).totals[:comments]
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

      it "returns zero as total if there are no reactions with points" do
        reaction = create(:reaction, reactable: article)
        reaction.update_columns(points: 0.0)
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

    describe "page views stats" do
      it "returns stats" do
        stats = described_class.new(user).totals[:page_views]
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

    it "returns stats for reactions for a user" do
      totals = described_class.new(user).totals
      expect(totals[:reactions].keys).to eq(%i[total like readinglist unicorn])
    end

    it "returns stats for follows for a user" do
      totals = described_class.new(user).totals
      expect(totals[:follows].keys).to eq([:total])
    end

    it "returns totals stats for an org" do
      totals = described_class.new(organization).totals
      expect(totals.keys).to eq(%i[comments reactions follows page_views])
    end
  end

  describe "#stats_grouped_by_day" do
    before do
      article = create(:article, user: user, published: true)
      create(:reaction, reactable: article)
      create(:reading_reaction, reactable: article)
      create(:page_view, user: user, article: article)
      create(:follow)
    end

    it "returns stats grouped by day" do
      stats = described_class.new(user, start_date: "2019-04-01", end_date: "2019-04-04").stats_grouped_by_day
      expect(stats.keys).to eq(["2019-04-01", "2019-04-02", "2019-04-03", "2019-04-04"])
    end

    it "returns stats for a specific day" do
      stats = described_class.new(user, start_date: "2019-04-01", end_date: "2019-04-04").stats_grouped_by_day
      expect(stats["2019-04-01"].keys).to eq(%i[comments reactions page_views follows])
    end
  end
end
