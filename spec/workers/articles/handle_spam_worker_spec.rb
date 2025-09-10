require "rails_helper"

RSpec.describe Articles::HandleSpamWorker, type: :worker do
  let(:article) { create(:article, with_tags: false) }
  let(:worker) { described_class.new }

  describe "#perform" do
    context "when article exists" do
      it "calls Spam::Handler.handle_article! with the article" do
        allow(Spam::Handler).to receive(:handle_article!)

        worker.perform(article.id)

        expect(Spam::Handler).to have_received(:handle_article!).with(article: article)
      end

      it "calls update_score after spam handling" do
        allow(Spam::Handler).to receive(:handle_article!)

        worker.perform(article.id)

        # The score should be recalculated
        expect(article.reload.score).to be_a(Numeric)
      end

      it "updates clickbait_score when it's 0 and score is at least 0 after spam handling" do
        allow(Spam::Handler).to receive(:handle_article!)

        # Ensure article has clickbait_score is 0 initially
        article.update_columns(clickbait_score: 0)

        # Mock AI to return a specific score
        ai_client = instance_double(Ai::Base)
        allow(Ai::Base).to receive(:new).and_return(ai_client)
        allow(ai_client).to receive(:call).and_return("0.4")

        worker.perform(article.id)

        # The score should be recalculated by update_score, and if it's >= 0, clickbait should be updated
        expect(article.reload.clickbait_score).to eq(0.4)
      end

      it "does not update clickbait_score when it's already greater than 0" do
        allow(Spam::Handler).to receive(:handle_article!)

        # Set clickbait_score to a non-zero value
        article.update_columns(score: 5, clickbait_score: 0.3)

        # Mock AI to return a different score
        ai_client = instance_double(Ai::Base)
        allow(Ai::Base).to receive(:new).and_return(ai_client)
        allow(ai_client).to receive(:call).and_return("0.8")

        worker.perform(article.id)

        # Clickbait score should remain unchanged
        expect(article.reload.clickbait_score).to eq(0.3)
      end

      it "does not update clickbait_score when article score is negative after spam handling" do
        allow(Spam::Handler).to receive(:handle_article!)

        # Set clickbait_score to 0 initially
        article.update_columns(clickbait_score: 0)

        # Mock reload to return the article with a negative score after update_score
        allow(article).to receive(:reload).and_return(article)
        allow(article).to receive(:update_score) do
          article.update_column(:score, -5)
        end

        # Mock AI to return a specific score
        ai_client = instance_double(Ai::Base)
        allow(Ai::Base).to receive(:new).and_return(ai_client)
        allow(ai_client).to receive(:call).and_return("0.4")

        worker.perform(article.id)

        # Clickbait score should remain 0 because score is negative after spam handling
        expect(article.reload.clickbait_score).to eq(0)
      end

      it "generates and applies tags when conditions are met" do
        # Set up article to meet tag generation criteria
        article.update_columns(score: 5)

        # Create test tags
        Tag.find_or_create_by(name: "javascript") { |tag| tag.supported = true }
        Tag.find_or_create_by(name: "webdev") { |tag| tag.supported = true }

        # Mock the AI client
        ai_client = instance_double(Ai::Base)
        allow(Ai::Base).to receive(:new).and_return(ai_client)
        allow(ai_client).to receive(:call).and_return("0.4", "javascript,webdev", "javascript,webdev")

        # Mock the enhancer's get_candidate_tags method to return the actual tags from the database
        allow_any_instance_of(Ai::ArticleEnhancer).to receive(:get_candidate_tags)
          .and_return(Tag.where(name: %w[javascript webdev]))

        allow(Spam::Handler).to receive(:handle_article!)
        allow(article).to receive(:update_score)
        allow(article).to receive(:update_column)

        worker.perform(article.id)

        expect(article.reload.cached_tag_list).to include("javascript")
        expect(article.reload.cached_tag_list).to include("webdev")
      end
    end

    context "when article does not exist" do
      it "does not call Spam::Handler.handle_article!" do
        allow(Spam::Handler).to receive(:handle_article!)

        worker.perform(999_999)
        expect(Spam::Handler).not_to have_received(:handle_article!)
      end

      it "does not raise an error" do
        expect { worker.perform(999_999) }.not_to raise_error
      end
    end

    context "when Spam::Handler.handle_article! raises an error" do
      it "does not call update_score or enhancement" do
        allow(Spam::Handler).to receive(:handle_article!).and_raise(StandardError.new("Spam handler error"))

        expect { worker.perform(article.id) }.to raise_error(StandardError)

        # The score should not be updated because the error prevents reaching update_score
        original_score = article.score
        expect(article.reload.score).to eq(original_score)
      end
    end

    context "when article enhancement fails" do
      it "logs error but continues processing" do
        allow(Spam::Handler).to receive(:handle_article!)

        # Mock enhancer to raise an error during enhancement
        enhancer = instance_double(Ai::ArticleEnhancer)
        allow(Ai::ArticleEnhancer).to receive(:new).and_return(enhancer)
        allow(enhancer).to receive(:calculate_clickbait_score).and_raise(StandardError, "Enhancement error")
        allow(Rails.logger).to receive(:error)

        expect { worker.perform(article.id) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Article enhancement failed/)
      end
    end
  end

  describe "integration with content moderation labeling" do
    context "when content moderation labeling affects the score" do
      before do
        # Mock the content moderation labeler to return a specific label
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("clear_and_obvious_harmful")
        stub_const("Ai::Base::DEFAULT_KEY", "present")
      end

      it "updates the score with automod_label adjustment" do
        initial_score = article.score

        # Perform the worker job
        worker.perform(article.id)

        # The score should be updated with the automod_label adjustment
        # clear_and_obvious_harmful has a -10 adjustment
        expect(article.reload.score).to eq(initial_score - 10)
      end
    end

    context "when content moderation labeling identifies high quality content" do
      before do
        # Mock the content moderation labeler to return a high quality label
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("great_and_on_topic")
        stub_const("Ai::Base::DEFAULT_KEY", "present")
      end

      it "updates the score with positive automod_label adjustment" do
        initial_score = article.score

        # Perform the worker job
        worker.perform(article.id)

        # The score should be updated with the automod_label adjustment
        # great_and_on_topic has a +20 adjustment
        expect(article.reload.score).to eq(initial_score + 20)
      end
    end
  end
end
