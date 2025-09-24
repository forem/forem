require "rails_helper"

RSpec.describe Articles::LabelCleanupWorker, type: :worker do
  let(:worker) { described_class.new }

  describe "#perform" do
    let!(:user) { create(:user) }

    context "when there are eligible articles" do
      it "processes eligible articles and enqueues HandleSpamWorker jobs" do
        # Create articles within the eligible time range
        article1 = create(:article, user: user, published: true, automod_label: "no_moderation_label")
        article1.update_columns(published_at: 1.hour.ago)
        
        article2 = create(:article, user: user, published: true, automod_label: "no_moderation_label")
        article2.update_columns(published_at: 2.hours.ago)

        expect(Articles::HandleSpamWorker).to receive(:perform_async).with(article1.id)
        expect(Articles::HandleSpamWorker).to receive(:perform_async).with(article2.id)

        worker.perform
      end

      it "logs the number of articles being processed" do
        # Create articles within the eligible time range
        article1 = create(:article, user: user, published: true, automod_label: "no_moderation_label")
        article1.update_columns(published_at: 1.hour.ago)
        
        article2 = create(:article, user: user, published: true, automod_label: "no_moderation_label")
        article2.update_columns(published_at: 2.hours.ago)

        allow(Rails.logger).to receive(:info)
        allow(Articles::HandleSpamWorker).to receive(:perform_async)

        worker.perform

        expect(Rails.logger).to have_received(:info).with("LabelCleanupWorker: Processing 2 articles with no_moderation_label")
        expect(Rails.logger).to have_received(:info).with("LabelCleanupWorker: Enqueued 2 HandleSpamWorker jobs")
      end

      it "limits to MAX_ARTICLES_PER_RUN when there are more articles" do
        # Create 80 articles (more than the max limit of 75)
        80.times do |i|
          article = create(:article, user: user, published: true, automod_label: "no_moderation_label")
          article.update_columns(published_at: (1 + i).hours.ago)
        end

        # Test that the query itself is limited
        eligible_articles = worker.send(:find_eligible_articles)
        expect(eligible_articles.size).to be <= Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN

        # Should only process up to 75 articles due to LIMIT clause
        expect(Articles::HandleSpamWorker).to receive(:perform_async).at_most(75).times

        worker.perform
      end
    end

    context "when there are no eligible articles" do
      it "does not enqueue any HandleSpamWorker jobs" do
        expect(Articles::HandleSpamWorker).not_to receive(:perform_async)

        worker.perform
      end

      it "logs that no eligible articles were found" do
        allow(Rails.logger).to receive(:info)

        worker.perform

        expect(Rails.logger).to have_received(:info).with("LabelCleanupWorker: No eligible articles found for processing")
      end
    end

    context "when articles exist but are not eligible" do
      it "does not process articles that are too recent" do
        # Create article that's too recent (5 minutes ago)
        article = create(:article, user: user, published: true, automod_label: "no_moderation_label")
        article.update_columns(published_at: 5.minutes.ago)

        expect(Articles::HandleSpamWorker).not_to receive(:perform_async)

        worker.perform
      end

      it "does not process articles with different labels" do
        # Create article with different label
        article = create(:article, user: user, published: true, automod_label: "okay_and_on_topic")
        article.update_columns(published_at: 1.hour.ago)

        expect(Articles::HandleSpamWorker).not_to receive(:perform_async)

        worker.perform
      end

      it "logs that no eligible articles were found when none exist" do
        allow(Rails.logger).to receive(:info)

        worker.perform

        expect(Rails.logger).to have_received(:info).with("LabelCleanupWorker: No eligible articles found for processing")
      end
    end
  end

  describe "private methods" do
    describe "#find_eligible_articles" do
      let!(:user) { create(:user) }
      let!(:eligible_article) do
        article = create(:article, user: user, published: true, automod_label: "no_moderation_label")
        article.update_columns(published_at: 1.hour.ago)
        article
      end

      let!(:ineligible_article) do
        article = create(:article, user: user, published: true, automod_label: "okay_and_on_topic")
        article.update_columns(published_at: 1.hour.ago)
        article
      end

      it "returns only published articles with no_moderation_label in the correct time range" do
        eligible_articles = worker.send(:find_eligible_articles)

        expect(eligible_articles).to include(eligible_article)
        expect(eligible_articles).not_to include(ineligible_article)
      end

      it "orders results randomly and limits to MAX_ARTICLES_PER_RUN" do
        older_article = create(:article, user: user, published: true, automod_label: "no_moderation_label")
        older_article.update_columns(published_at: 6.hours.ago)

        eligible_articles = worker.send(:find_eligible_articles)

        # Should return articles in random order and be limited to MAX_ARTICLES_PER_RUN
        expect(eligible_articles.size).to be <= Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN
        expect(eligible_articles).to include(older_article)
        expect(eligible_articles).to include(eligible_article)
      end
    end
  end

  describe "constants" do
    it "has the correct MAX_ARTICLES_PER_RUN value" do
      expect(Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN).to eq(75)
    end
  end
end
