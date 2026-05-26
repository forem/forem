require "rails_helper"

RSpec.describe Articles::UpdateArticleActivityWorker do
  let(:article) { create(:article) }
  let(:day) { 2.days.ago.utc.to_date }
  let(:iso) { day.iso8601 }

  it "is a no-op when article_id is nil" do
    expect { described_class.new.perform(nil) }.not_to raise_error
  end

  it "is a no-op when article does not exist" do
    expect { described_class.new.perform(0) }.not_to change(ArticleActivity, :count)
  end

  context "when no activity row exists yet (upsert path)" do
    it "creates the row and runs a full recompute from raw rows" do
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      create(:page_view, article: article, created_at: ts,
                         counts_for_number_of_views: 7, domain: "x.com")

      expect do
        described_class.new.perform(article.id, "page_view", "create",
                                    "iso" => iso, "total" => 1,
                                    "sum_read_seconds" => 0, "logged_in_count" => 0,
                                    "domain" => "x.com")
      end.to change(ArticleActivity, :count).by(1)

      activity = ArticleActivity.find_by(article_id: article.id)
      # full recompute reflected, not just the supplied delta
      expect(activity.daily_page_views[iso]["total"]).to eq(7)
    end
  end

  context "when activity row already exists" do
    let!(:activity) { ArticleActivity.create!(article: article) }

    it "recomputes page views from database page_views table and ignores delta arguments" do
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      create(:page_view, article: article, created_at: ts,
                         counts_for_number_of_views: 3, domain: "y.com")

      # Even when passing legacy delta arguments, it does a full recompute from database
      described_class.new.perform(article.id, "page_view", "create",
                                  "iso" => iso, "total" => 50,
                                  "sum_read_seconds" => 30, "logged_in_count" => 1,
                                  "domain" => "y.com")
      activity.reload
      expect(activity.daily_page_views[iso]["total"]).to eq(3)
      expect(activity.total_page_views).to eq(3)
    end

    it "recomputes reactions from database reactions table" do
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      # Create reaction
      reaction = create(:reaction, reactable: article, created_at: ts, category: "like")
      described_class.new.perform(article.id)
      activity.reload
      expect(activity.daily_reactions.dig(iso, "total").to_i).to eq(1)
      expect(activity.total_reactions).to eq(1)

      # Destroy reaction
      reaction.destroy!
      described_class.new.perform(article.id)
      activity.reload
      expect(activity.daily_reactions.dig(iso, "total").to_i).to eq(0)
      expect(activity.total_reactions).to eq(0)
    end

    it "recomputes comments from database comments table" do
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      create(:comment, commentable: article, created_at: ts, score: 1)
      described_class.new.perform(article.id)
      activity.reload
      expect(activity.daily_comments[iso]).to eq(1)
      expect(activity.total_comments).to eq(1)
    end
  end

  context "when enqueued via perform_async" do
    before { Sidekiq::Testing.fake! }

    it "runs immediately if the article has never been aggregated (last_aggregated_at is nil)" do
      described_class.perform_async(article.id)
      expect(described_class.jobs.size).to eq(1)
      job = described_class.jobs.first
      expect(job["args"]).to eq([article.id])
      expect(job["at"]).to be_nil
    end

    it "runs immediately if the last aggregation was longer ago than the debounce delay" do
      # Create activity with old last_aggregated_at
      ArticleActivity.create!(article: article, last_aggregated_at: 1.hour.ago)

      described_class.perform_async(article.id)
      expect(described_class.jobs.size).to eq(1)
      job = described_class.jobs.first
      expect(job["at"]).to be_nil
    end

    it "schedules with the remaining delay if the last aggregation was recent" do
      # Set page_views_count to 10k so base delay is 1 minute (60 seconds)
      article.update_column(:page_views_count, 15_000)
      # Last aggregated 20 seconds ago -> remaining delay = 40 seconds
      ArticleActivity.create!(article: article, last_aggregated_at: 20.seconds.ago)

      described_class.perform_async(article.id)
      expect(described_class.jobs.size).to eq(1)
      job = described_class.jobs.first
      expect(job["at"]).to be_within(2.seconds).of((Time.now + 40.seconds).to_f)
    end

    it "calculates dynamic delay based on page views and age boundaries" do
      # 1. Low views (< 1k), new article (0 days old) -> base 10 seconds
      expect(described_class.debounce_delay_for(0, Time.current)).to be_within(1.second).of(10.seconds)
      expect(described_class.debounce_delay_for(999, Time.current)).to be_within(1.second).of(10.seconds)

      # 2. Medium views (1k - 10k), 0 days old -> base 30 seconds
      expect(described_class.debounce_delay_for(1_000, Time.current)).to be_within(1.second).of(30.seconds)
      expect(described_class.debounce_delay_for(9_999, Time.current)).to be_within(1.second).of(30.seconds)

      # 3. High views (10k - 100k), 0 days old -> base 1 minute
      expect(described_class.debounce_delay_for(10_000, Time.current)).to be_within(1.second).of(1.minute)
      expect(described_class.debounce_delay_for(99_999, Time.current)).to be_within(1.second).of(1.minute)

      # 4. Extremely high views (>= 100k), 0 days old -> base 5 minutes
      expect(described_class.debounce_delay_for(100_000, Time.current)).to be_within(1.second).of(5.minutes)
      expect(described_class.debounce_delay_for(500_000, Time.current)).to be_within(1.second).of(5.minutes)

      # Age multipliers (exponential backoff)
      # 5. Low views, 1 day old article -> 10 seconds * 1.5^1 = 15 seconds
      expect(described_class.debounce_delay_for(500, 1.day.ago)).to be_within(1.second).of(15.seconds)

      # 6. Low views, 5 days old article -> 10 seconds * 1.5^5 (7.59) = 75.9 seconds
      expect(described_class.debounce_delay_for(500, 5.days.ago)).to be_within(1.second).of(75.9.seconds)

      # 7. Extremely old article (e.g. 100 days) -> capped at 30 minutes
      expect(described_class.debounce_delay_for(500, 100.days.ago)).to eq(30.minutes)
    end
  end
end
