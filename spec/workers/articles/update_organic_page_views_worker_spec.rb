require "rails_helper"

RSpec.describe Articles::UpdateOrganicPageViewsWorker, type: :worker do
  let(:worker) { described_class.new }
  let!(:article) { create(:article) }
  let(:google_referrer) { described_class::GOOGLE_REFERRER }

  it "sums past-month Google page views into organic_page_views_past_month_count" do
    create(:page_view, article: article, referrer: google_referrer, counts_for_number_of_views: 2)
    create(:page_view, article: article, referrer: google_referrer, counts_for_number_of_views: 3)
    create(:page_view, article: article, referrer: "https://example.com/", counts_for_number_of_views: 5)
    create(:page_view, article: article, referrer: google_referrer, counts_for_number_of_views: 7,
                       created_at: 2.months.ago)

    worker.perform(article.id)

    expect(article.reload.organic_page_views_past_month_count).to eq(5)
  end

  it "only loads the columns it needs from the article" do
    queries = []
    callback = lambda { |*, payload| queries << payload[:sql] if payload[:sql].include?('FROM "articles"') }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { worker.perform(article.id) }

    expect(queries).not_to be_empty
    expect(queries.grep(/"articles"\.\*/)).to be_empty
  end

  it "raises when the article does not exist" do
    expect { worker.perform(0) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
