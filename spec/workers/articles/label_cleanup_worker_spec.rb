require "rails_helper"

RSpec.describe Articles::LabelCleanupWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:user) { create(:user, :without_profile, profile_image: nil) }

  def create_cleanup_article(published_at:, **attributes)
    article = create(
      :article,
      user: user,
      published: true,
      automod_label: "no_moderation_label",
      with_tags: false,
      **attributes,
    )
    article.update_columns(published_at: published_at)
    article
  end

  describe "#perform" do
    context "when there are eligible articles" do
      it "processes eligible articles, enqueues HandleSpamWorker jobs, and logs progress", :aggregate_failures do
        article1 = create_cleanup_article(published_at: 1.hour.ago)
        article2 = create_cleanup_article(published_at: 2.hours.ago)

        allow(Rails.logger).to receive(:info)
        allow(Articles::HandleSpamWorker).to receive(:perform_async)

        worker.perform

        expect(Articles::HandleSpamWorker).to have_received(:perform_async).with(article2.id).ordered
        expect(Articles::HandleSpamWorker).to have_received(:perform_async).with(article1.id).ordered
        expect(Rails.logger).to have_received(:info).with(
          "LabelCleanupWorker: Processing 2 articles with no_moderation_label",
        )
        expect(Rails.logger).to have_received(:info).with(
          "LabelCleanupWorker: Enqueued 2 HandleSpamWorker jobs",
        )
      end

      it "limits to MAX_ARTICLES_PER_RUN when there are more articles", :aggregate_failures do
        stub_const("Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN", 2)

        3.times do |i|
          create_cleanup_article(published_at: (15 + i).minutes.ago)
        end

        eligible_articles = worker.__send__(:find_eligible_articles)
        expect(eligible_articles.limit_value).to eq(Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN)
        expect(eligible_articles.size).to eq(2)

        allow(Articles::HandleSpamWorker).to receive(:perform_async)

        worker.perform

        expect(Articles::HandleSpamWorker).to have_received(:perform_async).twice
      end
    end

    context "when there are no eligible articles" do
      it "does not enqueue any HandleSpamWorker jobs and logs that none were found", :aggregate_failures do
        allow(Rails.logger).to receive(:info)
        allow(Articles::HandleSpamWorker).to receive(:perform_async)

        worker.perform

        expect(Articles::HandleSpamWorker).not_to have_received(:perform_async)
        expect(Rails.logger).to have_received(:info).with(
          "LabelCleanupWorker: No eligible articles found for processing",
        )
      end
    end

    context "when articles exist but are not eligible" do
      it "does not process articles that are too recent and logs that none were found", :aggregate_failures do
        create_cleanup_article(published_at: 5.minutes.ago)
        allow(Rails.logger).to receive(:info)
        allow(Articles::HandleSpamWorker).to receive(:perform_async)

        worker.perform

        expect(Articles::HandleSpamWorker).not_to have_received(:perform_async)
        expect(Rails.logger).to have_received(:info).with(
          "LabelCleanupWorker: No eligible articles found for processing",
        )
      end

      it "does not process articles with different labels" do
        create_cleanup_article(published_at: 1.hour.ago, automod_label: "okay_and_on_topic")
        allow(Articles::HandleSpamWorker).to receive(:perform_async)

        worker.perform

        expect(Articles::HandleSpamWorker).not_to have_received(:perform_async)
      end

      it "does not process articles with a score of -80 or lower" do
        create_cleanup_article(published_at: 1.hour.ago, score: -80)
        allow(Articles::HandleSpamWorker).to receive(:perform_async)

        worker.perform

        expect(Articles::HandleSpamWorker).not_to have_received(:perform_async)
      end
    end
  end

  describe "private methods" do
    describe "#find_eligible_articles" do
      let!(:eligible_article) { create_cleanup_article(published_at: 1.hour.ago) }
      let!(:ineligible_article) do
        create_cleanup_article(published_at: 1.hour.ago, automod_label: "okay_and_on_topic")
      end

      it "returns only published articles with no_moderation_label in the correct time range", :aggregate_failures do
        eligible_articles = worker.__send__(:find_eligible_articles)

        expect(eligible_articles).to include(eligible_article)
        expect(eligible_articles).not_to include(ineligible_article)
      end

      it "orders results by published_at ascending and limits to MAX_ARTICLES_PER_RUN", :aggregate_failures do
        older_article = create_cleanup_article(published_at: 6.hours.ago)

        eligible_articles = worker.__send__(:find_eligible_articles)

        expect(eligible_articles.limit_value).to eq(Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN)
        expect(eligible_articles.size).to be <= Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN
        expect(eligible_articles.to_a).to eq([older_article, eligible_article])
      end
    end
  end

  describe "constants" do
    it "has the correct MAX_ARTICLES_PER_RUN value" do
      expect(Articles::LabelCleanupWorker::MAX_ARTICLES_PER_RUN).to eq(150)
    end
  end
end
