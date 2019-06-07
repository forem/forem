require "rails_helper"

RSpec.describe ArticleAnalyticsFetcher do
  let(:stubbed_ga) { double }

  before do
    srand(2) # disabling #occasionally_force_fetch
    allow(Notification).to receive(:send_milestone_notification)
    allow(GoogleAnalytics).to receive(:new).and_return(stubbed_ga)
  end

  describe "#update_analytics" do
    context "when positive_reactions_count is LOWER than previous_positive_reactions_count" do
      it "does nothing " do
        article = build_stubbed(:article, positive_reactions_count: 2, previous_positive_reactions_count: 3)
        allow(Article).to receive(:where).and_return([article])
        described_class.new.update_analytics(1)
        expect(Notification).not_to have_received(:send_milestone_notification)
      end
    end

    context "when positive_reactions_count is HIGHER than previous_positive_reactions_count" do
      let(:article) { build_stubbed(:article, positive_reactions_count: 5, previous_positive_reactions_count: 3) }
      let(:pageview) { {} }
      let(:counts) { 1000 }

      before do
        pageview[article.id] = counts
        allow(stubbed_ga).to receive(:get_pageviews).and_return(pageview)
        allow(article).to receive(:update_columns)
        allow(Article).to receive(:where).and_return([article])
        described_class.new.update_analytics(1)
      end

      it "sends send_milestone_notification for Reaction and View" do
        %w[Reaction View].each do |type|
          expect(Notification).to have_received(:send_milestone_notification).with(type: type, article_id: article.id)
        end
      end

      it "updates appropriate column" do
        expect(article).to have_received(:update_columns).with(previous_positive_reactions_count: article.positive_reactions_count)
        expect(article).to have_received(:update_columns).with(page_views_count: counts)
      end
    end
  end
end
