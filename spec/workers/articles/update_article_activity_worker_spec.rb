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

    it "applies a page_view delta atomically" do
      described_class.new.perform(article.id, "page_view", "create",
                                  "iso" => iso, "total" => 3,
                                  "sum_read_seconds" => 30, "logged_in_count" => 1,
                                  "domain" => "y.com")
      activity.reload
      expect(activity.daily_page_views[iso]["total"]).to eq(3)
      expect(activity.total_page_views).to eq(3)
    end

    it "applies a reaction delta with sign +1 / -1" do
      described_class.new.perform(article.id, "reaction", "create",
                                  "iso" => iso, "category" => "like", "user_id" => 7)
      described_class.new.perform(article.id, "reaction", "destroy",
                                  "iso" => iso, "category" => "like", "user_id" => 7)
      activity.reload
      expect(activity.daily_reactions[iso]["total"]).to eq(0)
      expect(activity.total_reactions).to eq(0)
    end

    it "applies a comment delta" do
      described_class.new.perform(article.id, "comment", "create",
                                  "iso" => iso, "score" => 4)
      activity.reload
      expect(activity.daily_comments[iso]).to eq(1)
    end

    it "runs a full recompute when event_type is nil" do
      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      create(:page_view, article: article, created_at: ts,
                         counts_for_number_of_views: 11, domain: "z.com")
      described_class.new.perform(article.id)
      activity.reload
      expect(activity.daily_page_views[iso]["total"]).to eq(11)
    end
  end

  context "when enqueued via perform_async (debounced path)" do
    before { Sidekiq::Testing.fake! }

    it "queues a single debounced job and stores events in Redis" do
      described_class.perform_async(article.id, "page_view", "create",
                                    "iso" => iso, "total" => 2, "sum_read_seconds" => 10, "logged_in_count" => 1, "domain" => "google.com")
      described_class.perform_async(article.id, "page_view", "create",
                                    "iso" => iso, "total" => 3, "sum_read_seconds" => 15, "logged_in_count" => 1, "domain" => "google.com")
      described_class.perform_async(article.id, "reaction", "create",
                                    "iso" => iso, "category" => "like", "user_id" => 123)

      expect(described_class.jobs.size).to eq(1)
      job = described_class.jobs.first
      expect(job["args"]).to eq([article.id])
      expect(job["at"]).to be_present

      events = Sidekiq.redis { |r| r.lrange("article_activity_debounce:#{article.id}", 0, -1) }
      expect(events.size).to eq(3)

      parsed_events = events.map { |e| JSON.parse(e) }
      expect(parsed_events[0]["event_type"]).to eq("page_view")
      expect(parsed_events[1]["event_type"]).to eq("page_view")
      expect(parsed_events[2]["event_type"]).to eq("reaction")
    end

    it "adjusts the debounce delay dynamically based on page views" do
      # Test default (low page views)
      described_class.perform_async(article.id, "page_view", "create", "iso" => iso, "total" => 1)
      expect(described_class.jobs.first["at"]).to be_within(1.second).of((Time.now + 10.seconds).to_f)

      # Helper to clear state
      clear_state = -> {
        described_class.clear
        Sidekiq.redis { |r| r.del("article_activity_debounce:#{article.id}", "article_activity_debounce_scheduled:#{article.id}") }
      }

      # Test medium traffic (>= 1,000 views)
      clear_state.call
      article.update_column(:page_views_count, 2_000)
      described_class.perform_async(article.id, "page_view", "create", "iso" => iso, "total" => 1)
      expect(described_class.jobs.first["at"]).to be_within(1.second).of((Time.now + 30.seconds).to_f)

      # Test higher traffic (>= 10,000 views)
      clear_state.call
      article.update_column(:page_views_count, 15_000)
      described_class.perform_async(article.id, "page_view", "create", "iso" => iso, "total" => 1)
      expect(described_class.jobs.first["at"]).to be_within(1.second).of((Time.now + 1.minute).to_f)

      # Test extremely high traffic (>= 100,000 views)
      clear_state.call
      article.update_column(:page_views_count, 120_000)
      described_class.perform_async(article.id, "page_view", "create", "iso" => iso, "total" => 1)
      expect(described_class.jobs.first["at"]).to be_within(1.second).of((Time.now + 5.minutes).to_f)
      
      clear_state.call
    end

    it "coalesces and applies the debounced events when performed" do
      activity = ArticleActivity.create!(article: article)

      described_class.perform_async(article.id, "page_view", "create",
                                    "iso" => iso, "total" => 2, "sum_read_seconds" => 10, "logged_in_count" => 1, "domain" => "google.com")
      described_class.perform_async(article.id, "page_view", "create",
                                    "iso" => iso, "total" => 3, "sum_read_seconds" => 15, "logged_in_count" => 1, "domain" => "google.com")
      described_class.perform_async(article.id, "reaction", "create",
                                    "iso" => iso, "category" => "like", "user_id" => 123)

      described_class.clear

      described_class.new.perform(article.id)

      activity.reload
      expect(activity.page_views_by_day[iso]["total"]).to eq(5)
      expect(activity.page_views_by_day[iso]["average_read_time_in_seconds"]).to eq(13)
      expect(activity.daily_reactions[iso]["total"]).to eq(1)
      expect(activity.daily_reactions[iso]["like"]).to eq(1)

      Sidekiq.redis do |r|
        expect(r.lrange("article_activity_debounce:#{article.id}", 0, -1)).to be_empty
        expect(r.get("article_activity_debounce_scheduled:#{article.id}")).to be_nil
      end
    end

    it "prioritizes a full recompute if present in the debounced queue" do
      activity = ArticleActivity.create!(article: article)

      described_class.perform_async(article.id, "page_view", "create",
                                    "iso" => iso, "total" => 2, "sum_read_seconds" => 10, "logged_in_count" => 1, "domain" => "google.com")
      described_class.perform_async(article.id, nil)
      described_class.perform_async(article.id, "reaction", "create",
                                    "iso" => iso, "category" => "like", "user_id" => 123)

      ts = Time.utc(day.year, day.month, day.day, 12, 0, 0)
      create(:page_view, article: article, created_at: ts, counts_for_number_of_views: 10, domain: "z.com")

      described_class.clear

      described_class.new.perform(article.id)

      activity.reload
      expect(activity.daily_page_views[iso]["total"]).to eq(10)
    end
  end
end
