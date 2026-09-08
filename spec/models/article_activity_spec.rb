require "rails_helper"

RSpec.describe ArticleActivity do
  let(:article) { create(:article) }
  let(:activity) { described_class.create!(article: article) }

  let(:day) { 2.days.ago.utc.to_date }
  let(:iso) { day.iso8601 }

  describe "#apply_page_view_delta!" do
    it "atomically increments per-day counters and the rolling total" do
      activity.apply_page_view_delta!(
        "iso" => iso, "total" => 5, "sum_read_seconds" => 60, "logged_in_count" => 2,
        "domain" => "google.com",
      )
      activity.apply_page_view_delta!(
        "iso" => iso, "total" => 3, "sum_read_seconds" => 30, "logged_in_count" => 1,
        "domain" => "google.com",
      )

      raw = activity.daily_page_views[iso]
      expect(raw["total"]).to eq(8)
      expect(raw["sum_read_seconds"]).to eq(90)
      expect(raw["logged_in_count"]).to eq(3)
      expect(activity.total_page_views).to eq(8)
      # Referrer count matches sum of `total` (counts_for_number_of_views)
      # across the deltas, not the number of deltas.
      expect(activity.daily_referrers[iso]).to eq("google.com" => 8)
    end

    it "derives a response-shape day with weighted average read time" do
      activity.apply_page_view_delta!(
        "iso" => iso, "total" => 4, "sum_read_seconds" => 120, "logged_in_count" => 2,
        "domain" => nil,
      )
      day_response = activity.page_views_by_day[iso]
      expect(day_response["total"]).to eq(4)
      expect(day_response["average_read_time_in_seconds"]).to eq(60)
      expect(day_response["total_read_time_in_seconds"]).to eq(240)
    end
  end

  describe "#apply_reaction_delta!" do
    it "appends reactor ids and bumps category + total counters with sign +1" do
      activity.apply_reaction_delta!({ "iso" => iso, "category" => "like", "user_id" => 99 }, sign: 1)
      activity.apply_reaction_delta!({ "iso" => iso, "category" => "fire", "user_id" => 100 }, sign: 1)

      raw = activity.daily_reactions[iso]
      expect(raw["total"]).to eq(2)
      expect(raw["like"]).to eq(1)
      expect(raw["fire"]).to eq(1)
      expect(raw["reactor_ids"]).to contain_exactly(99, 100)
      expect(activity.total_reactions).to eq(2)
    end

    it "decrements totals on sign -1 (reactor_ids stay; documented tradeoff)" do
      activity.apply_reaction_delta!({ "iso" => iso, "category" => "like", "user_id" => 99 }, sign: 1)
      activity.apply_reaction_delta!({ "iso" => iso, "category" => "like", "user_id" => 99 }, sign: -1)

      raw = activity.daily_reactions[iso]
      expect(raw["total"]).to eq(0)
      expect(raw["like"]).to eq(0)
      expect(activity.total_reactions).to eq(0)
    end
  end

  describe "#apply_comment_delta!" do
    it "bumps integer day counter and rolling total when score is positive" do
      activity.apply_comment_delta!({ "iso" => iso, "score" => 5 }, sign: 1)
      activity.apply_comment_delta!({ "iso" => iso, "score" => 5 }, sign: 1)
      expect(activity.daily_comments[iso]).to eq(2)
      expect(activity.total_comments).to eq(2)

      activity.apply_comment_delta!({ "iso" => iso, "score" => 5 }, sign: -1)
      expect(activity.daily_comments[iso]).to eq(1)
      expect(activity.total_comments).to eq(1)
    end

    it "no-ops when iso is blank" do
      activity.apply_comment_delta!({ "iso" => "" }, sign: 1)
      expect(activity.daily_comments).to eq({})
      expect(activity.total_comments).to eq(0)
    end
  end

  describe "#recompute_all!" do
    it "rebuilds every column from raw rows" do
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      user = create(:user)
      pv = create(:page_view, article: article, user: user, created_at: ts,
                              counts_for_number_of_views: 4, time_tracked_in_seconds: 30)
      pv.update_column(:domain, "google.com")
      create(:reaction, reactable: article, user: user, category: "like", created_at: ts)
      create(:comment, commentable: article, user: user, score: 5, created_at: ts)

      activity.recompute_all!
      activity.reload

      expect(activity.daily_page_views[iso]["total"]).to eq(4)
      expect(activity.daily_reactions[iso]["like"]).to eq(1)
      expect(activity.daily_comments[iso]).to eq(1)
      expect(activity.daily_referrers[iso]).to eq("google.com" => 4)
      expect(activity.total_page_views).to eq(4)
      expect(activity.total_reactions).to eq(1)
      expect(activity.total_comments).to eq(1)
      expect(activity.last_aggregated_at).to be_present
    end
  end

  describe ".bulk_backfill!" do
    it "rebuilds multiple article rows from batch aggregates" do
      other_article = create(:article)
      user = create(:user)
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      page_view = create(
        :page_view,
        article: article,
        user: user,
        created_at: ts,
        counts_for_number_of_views: 4,
        time_tracked_in_seconds: 30,
      )
      page_view.update_column(:domain, "example.com")
      create(:page_view, article: other_article, created_at: ts,
                         counts_for_number_of_views: 2, domain: "forem.com")
      create(:reaction, reactable: article, user: user, category: "fire", created_at: ts)
      create(:comment, commentable: other_article, user: user, score: 5, created_at: ts)

      sql_queries = []
      callback = lambda do |*, payload|
        sql_queries << payload[:sql] unless %w[SCHEMA TRANSACTION].include?(payload[:name])
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.bulk_backfill!([article.id, other_article.id])
      end

      first = described_class.find_by!(article: article)
      second = described_class.find_by!(article: other_article)
      expected_page_views = {
        "total" => 4,
        "sum_read_seconds" => 30,
        "logged_in_count" => 1
      }
      expect(first).to have_attributes(
        daily_page_views: hash_including(iso => expected_page_views),
        daily_referrers: hash_including(iso => { "example.com" => 4 }),
        total_page_views: 4,
        total_reactions: 1,
        last_aggregated_at: be_present,
      )
      expect(first.daily_reactions[iso]["fire"]).to eq(1)
      expect(sql_queries.size).to eq(5)
      expect(second).to have_attributes(
        daily_page_views: hash_including(iso => hash_including("total" => 2)),
        daily_comments: hash_including(iso => 1),
        total_comments: 1,
        last_aggregated_at: be_present,
      )

      columns = %w[daily_page_views daily_reactions daily_comments daily_referrers
                   total_page_views total_reactions total_comments]
      [first, second].each do |record|
        bulk_values = record.attributes.slice(*columns)
        record.recompute_all!
        expect(record.reload.attributes.slice(*columns)).to eq(bulk_values)
      end
    end

    it "preserves a row created after aggregation but before insertion" do
      article_id = article.id
      allow(described_class).to receive(:insert_all).and_wrap_original do |original, *args, **kwargs|
        described_class.create!(article_id: article_id, total_page_views: 99)
        original.call(*args, **kwargs)
      end

      described_class.bulk_backfill!([article_id])

      expect(described_class.find_by!(article_id: article_id).total_page_views).to eq(99)
    end
  end

  describe "#referrer_totals" do
    it "sorts by count desc and limits" do
      activity.apply_page_view_delta!("iso" => iso, "total" => 1, "sum_read_seconds" => 0,
                                      "logged_in_count" => 0, "domain" => "a.com")
      activity.apply_page_view_delta!("iso" => iso, "total" => 1, "sum_read_seconds" => 0,
                                      "logged_in_count" => 0, "domain" => "a.com")
      activity.apply_page_view_delta!("iso" => iso, "total" => 1, "sum_read_seconds" => 0,
                                      "logged_in_count" => 0, "domain" => "b.com")
      result = activity.referrer_totals(top: 5)
      expect(result[:domains].first).to eq(domain: "a.com", count: 2)
    end
  end
end
