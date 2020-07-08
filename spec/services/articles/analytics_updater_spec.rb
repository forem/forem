require "rails_helper"

RSpec.describe Articles::AnalyticsUpdater, type: :service do
  let(:stubbed_ga) { double }
  let(:user) { build(:user) }

  before do
    srand(2) # disabling #occasionally_force_fetch
    allow(Notification).to receive(:send_milestone_notification)
  end

  describe "#call" do
    context "when public_reactions_count is LOWER than previous_public_reactions_count" do
      it "does nothing " do
        build_stubbed(:article, public_reactions_count: 2, previous_public_reactions_count: 3, user: user)
        described_class.call(user)
        expect(Notification).not_to have_received(:send_milestone_notification)
      end
    end

    context "when public_reactions_count is HIGHER than previous_public_reactions_count" do
      let(:article) do
        build_stubbed(:article, public_reactions_count: 5, previous_public_reactions_count: 3, user: user)
      end
      let(:pageview) { {} }
      let(:counts) { 1000 }
      let(:user_articles) { double }
      let(:analytics_updater_service) { described_class.new(user) }

      before do
        pageview[article.id] = counts
        allow(stubbed_ga).to receive(:get_pageviews).and_return(pageview)
        allow(article).to receive(:update_columns)
        allow(analytics_updater_service).to receive(:published_articles).and_return([article])
        analytics_updater_service.call
      end

      xit "sends send_milestone_notification for Reaction and View" do
        %w[Reaction View].each do |type|
          expect(Notification).to have_received(:send_milestone_notification).with(type: type, article_id: article.id)
        end
      end

      it "updates appropriate column" do
        count = article.public_reactions_count
        expect(article).to have_received(:update_columns).with(previous_public_reactions_count: count)
      end
    end
  end
end
