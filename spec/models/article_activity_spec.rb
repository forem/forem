require "rails_helper"

RSpec.describe ArticleActivity do
  let(:article) { create(:article) }
  let(:activity) { described_class.create!(article: article) }

  let(:day) { 2.days.ago.utc.to_date }
  let(:iso) { day.iso8601 }

  describe ".daily_counters_between" do
    it "loads only the requested days and leaves out reactor ids and referrers", :aggregate_failures do
      described_class.create!(
        article: article,
        daily_page_views: {
          "2026-02-28" => { "total" => 9, "sum_read_seconds" => 0, "logged_in_count" => 0 },
          "2026-03-01" => { "total" => 3, "sum_read_seconds" => 30, "logged_in_count" => 1 }
        },
        daily_reactions: {
          "2026-03-01" => { "total" => 2, "like" => 1, "readinglist" => 1, "reactor_ids" => [1, 2] },
          "2026-03-03" => { "total" => 1, "fire" => 1, "reactor_ids" => [3] }
        },
        daily_comments: { "2026-03-02" => 4, "2026-03-03" => 1 },
        daily_referrers: { "2026-03-01" => { "google.com" => 3 } },
      )

      rollup = described_class.daily_counters_between(Date.new(2026, 3, 1), Date.new(2026, 3, 2))
        .find_by!(article_id: article.id)

      expect(rollup.daily_page_views).to eq(
        "2026-03-01" => { "total" => 3, "sum_read_seconds" => 30, "logged_in_count" => 1 },
      )
      expect(rollup.daily_reactions).to eq("2026-03-01" => { "total" => 2, "like" => 1, "readinglist" => 1 })
      expect(rollup.daily_comments).to eq("2026-03-02" => 4)
      expect(rollup.has_attribute?(:daily_referrers)).to be(false)
    end

    it "returns empty counters when no day falls in the range" do
      described_class.create!(article: article, daily_comments: { "2026-02-01" => 2 })

      rollup = described_class.daily_counters_between(Date.new(2026, 3, 1), Date.new(2026, 3, 2))
        .find_by!(article_id: article.id)

      expect([rollup.daily_page_views, rollup.daily_reactions, rollup.daily_comments]).to eq([{}, {}, {}])
    end
  end

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

    it "rolls multiple referrer domains into one day from a single page_views scan" do
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      user = create(:user)
      create(:page_view, article: article, user: user, created_at: ts,
                         counts_for_number_of_views: 3, time_tracked_in_seconds: 20)
        .update_column(:domain, "a.com")
      create(:page_view, article: article, user: nil, created_at: ts,
                         counts_for_number_of_views: 2, time_tracked_in_seconds: 50)
        .update_column(:domain, "b.com")
      create(:page_view, article: article, user: nil, created_at: ts, counts_for_number_of_views: 1)
        .update_column(:domain, nil)

      page_view_queries = []
      callback = lambda do |*, payload|
        page_view_queries << payload[:sql] if payload[:sql].include?('FROM "page_views"')
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { activity.recompute_all! }
      activity.reload

      expect(page_view_queries.size).to eq(1)
      expect(activity.daily_page_views[iso]).to eq(
        "total" => 6, "sum_read_seconds" => 20, "logged_in_count" => 1,
      )
      expect(activity.daily_referrers[iso]).to eq("a.com" => 3, "b.com" => 2, "" => 1)
      expect(activity.total_page_views).to eq(6)
    end

    it "does not load the article row when saving" do
      create(:page_view, article: article, created_at: Time.utc(day.year, day.month, day.day, 12, 0, 0))
      fresh_activity = described_class.find(activity.id)

      article_queries = []
      callback = lambda do |*, payload|
        article_queries << payload[:sql] if payload[:sql].include?('FROM "articles"')
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { fresh_activity.recompute_all! }

      expect(article_queries).to be_empty
      expect(fresh_activity.reload.total_page_views).to eq(1)
      expect(fresh_activity.last_aggregated_at).to be_present
    end

    context "with the ForemNative single-UPDATE fast path" do
      let(:ts) { Time.utc(day.year, day.month, day.day, 12, 0, 0) }
      let(:columns) do
        %w[daily_page_views daily_reactions daily_comments daily_referrers
           total_page_views total_reactions total_comments]
      end

      before do
        user = create(:user)
        create(:page_view, article: article, user: user, created_at: ts,
                           counts_for_number_of_views: 3, time_tracked_in_seconds: 20)
          .update_column(:domain, "o'neil.example")
        create(:page_view, article: article, user: nil, created_at: ts, counts_for_number_of_views: 2)
          .update_column(:domain, nil)
        create(:reaction, reactable: article, user: user, category: "like", created_at: ts)
        create(:reaction, reactable: article, user: create(:user), category: "fire", created_at: ts)
        create(:comment, commentable: article, user: user, score: 5, created_at: ts)
      end

      it "persists exactly what the legacy ActiveRecord save path persists", :aggregate_failures do
        generated_sql = []
        allow(ForemNative).to receive(:article_activity_recompute_sql).and_wrap_original do |original, *args|
          sql = original.call(*args)
          generated_sql << sql
          sql
        end

        activity.recompute_all!
        expect(generated_sql).to contain_exactly(a_kind_of(String))
        native_values = activity.reload.attributes.slice(*columns)

        allow(ForemNative).to receive(:article_activity_recompute_sql).and_return(nil)
        described_class.where(id: activity.id).update_all(
          daily_page_views: {}, daily_reactions: {}, daily_comments: {}, daily_referrers: {},
          total_page_views: 0, total_reactions: 0, total_comments: 0
        )
        activity.reload.recompute_all!

        expect(activity.reload.attributes.slice(*columns)).to eq(native_values)
        expect(native_values["daily_referrers"][iso]).to eq("o'neil.example" => 3, "" => 2)
        expect(native_values["daily_reactions"][iso]).to include("total" => 2, "like" => 1, "fire" => 1)
        expect(native_values["daily_reactions"][iso]["reactor_ids"].size).to eq(2)
        expect(native_values).to include("total_page_views" => 5, "total_reactions" => 2, "total_comments" => 1)
      end

      it "writes the rollup with a single UPDATE and refreshes a fully loaded record" do
        activity # create the row before subscribing
        writes = []
        callback = lambda do |*, payload|
          writes << payload[:sql] if payload[:sql].match?(/\A\s*(UPDATE|INSERT)/i)
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { activity.recompute_all! }

        expect(writes.size).to eq(1)
        expect(activity.daily_page_views[iso]).to eq("total" => 5, "sum_read_seconds" => 20, "logged_in_count" => 1)
        expect(activity.total_comments).to eq(1)
        expect(activity.last_aggregated_at).to be_present
      end

      it "recomputes a record loaded with only its key columns without loading the jsonb rollups" do
        keyed = described_class.select(*described_class::KEY_COLUMNS).find(activity.id)

        expect(keyed.recompute_all!).to be(true)
        expect(keyed.has_attribute?(:daily_page_views)).to be(false)
        expect(activity.reload.total_page_views).to eq(5)
        expect(activity.daily_comments[iso]).to eq(1)
      end

      it "reloads a key-only record before falling back to the legacy save path" do
        allow(ForemNative).to receive(:article_activity_recompute_sql).and_return(nil)
        keyed = described_class.select(*described_class::KEY_COLUMNS).find(activity.id)

        expect { keyed.recompute_all! }.not_to raise_error
        expect(activity.reload.total_page_views).to eq(5)
        expect(activity.daily_referrers[iso]).to eq("o'neil.example" => 3, "" => 2)
      end

      it "matches the legacy Ruby rollup builders for the plucked rows" do
        page_view_rows = activity.__send__(:page_view_rollup_rows)
        reaction_rows = activity.__send__(:reaction_rollup_rows)
        comment_rows = activity.__send__(:comment_rollup_rows)
        pv, rf = described_class.legacy_page_views_and_referrers(page_view_rows)
        rx = described_class.legacy_reactions(reaction_rows)

        native = ForemNative.article_activity_rollup_json(page_view_rows, reaction_rows, comment_rows)

        expect(native.first(4).map { |json| JSON.parse(json) })
          .to eq([pv, rx, comment_rows.to_h, rf].map { |h| JSON.parse(ActiveSupport::JSON.encode(h)) })
        expect(page_view_rows.map(&:first).uniq).to eq([iso])
      end
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
