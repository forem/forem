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
end
