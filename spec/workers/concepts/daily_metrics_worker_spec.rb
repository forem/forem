require "rails_helper"

RSpec.describe Concepts::DailyMetricsWorker, type: :worker do
  let!(:concept) { create(:concept) }
  let!(:article) do
    art = create(:article, published: true)
    art.update_column(:published_at, 1.day.ago)
    art
  end
  let!(:membership_article) { create(:concept_membership, concept: concept, record: article) }

  let!(:comment_mapped) do
    com = create(:comment)
    com.update_column(:created_at, 1.day.ago)
    com
  end
  let!(:membership_comment) { create(:concept_membership, concept: concept, record: comment_mapped) }

  before do
    # Add page views for yesterday
    create(:page_view, article: article, counts_for_number_of_views: 10, created_at: 1.day.ago)
    create(:page_view, article: article, counts_for_number_of_views: 5, created_at: 1.day.ago)

    # Add reactions for yesterday:
    # 2 on the article
    create(:reaction, reactable: article, category: "like", created_at: 1.day.ago)
    create(:reaction, reactable: article, category: "unicorn", created_at: 1.day.ago)
    # 1 on the mapped comment
    create(:reaction, reactable: comment_mapped, category: "like", created_at: 1.day.ago)

    # Add comment for yesterday:
    # 1 under the mapped article (not directly mapped itself)
    create(:comment, commentable: article, created_at: 1.day.ago)

    # Add page view for today to make sure yesterday's query doesn't capture it
    create(:page_view, article: article, counts_for_number_of_views: 100, created_at: Time.current)
  end

  it "aggregates metrics for yesterday and computes popularity score" do
    expect {
      described_class.new.perform
    }.to change(ConceptDailyMetric, :count).by(1)

    metric = ConceptDailyMetric.last
    expect(metric.concept).to eq(concept)
    expect(metric.date).to eq(Date.yesterday)
    expect(metric.articles_count).to eq(1) # article published 1 day ago
    expect(metric.page_views).to eq(15) # 10 + 5
    expect(metric.reactions_count).to eq(3) # 2 on article + 1 on mapped comment
    # comments_count: 1 (directly mapped comment_mapped) + 1 (under article) = 2
    expect(metric.comments_count).to eq(2)

    # score = (articles_count * 10) + (reactions * 1) + (comments * 2) + (views * 0.1)
    # score = (1 * 10) + (3 * 1) + (2 * 2) + (15 * 0.1) = 10 + 3 + 4 + 1.5 = 18.5
    expect(metric.popularity_score).to eq(18.5)
  end

  it "supports backfilling for a specific date string" do
    target_date = "2026-05-15"
    target_time = Time.zone.parse(target_date)

    # Clean up default setup or modify its dates
    article.update_column(:published_at, target_time + 4.hours)
    comment_mapped.update_column(:created_at, target_time + 1.hour)
    PageView.update_all(created_at: target_time + 2.hours)
    Reaction.update_all(created_at: target_time + 3.hours)
    Comment.update_all(created_at: target_time + 4.hours)

    described_class.new.perform(target_date)

    metric = ConceptDailyMetric.find_by(date: target_date)
    expect(metric).to be_present
    expect(metric.articles_count).to eq(1)
    expect(metric.page_views).to eq(115) # 10 + 5 + 100
  end
end
