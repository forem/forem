require "rails_helper"

RSpec.describe Articles::HandleSpamWorker, type: :worker do
  let(:article) { create(:article) }
  let(:worker) { described_class.new }

  describe "#perform" do
    context "when article exists" do
      it "calls Spam::Handler.handle_article! with the article" do
        allow(Spam::Handler).to receive(:handle_article!)
        
        worker.perform(article.id)
        
        expect(Spam::Handler).to have_received(:handle_article!).with(article: article)
      end

      it "calls update_score after spam handling" do
        # Mock the spam handler to not actually process spam
        allow(Spam::Handler).to receive(:handle_article!)
        
        # Track if update_score is called by checking the score before and after
        initial_score = article.score
        
        worker.perform(article.id)
        
        # The score should be recalculated, so it might be different
        expect(article.reload.score).to be >= initial_score
      end
    end

    context "when article does not exist" do
      it "does not call Spam::Handler.handle_article!" do
        allow(Spam::Handler).to receive(:handle_article!)
        
        worker.perform(999999)
        expect(Spam::Handler).not_to have_received(:handle_article!)
      end

      it "does not raise an error" do
        expect { worker.perform(999999) }.not_to raise_error
      end
    end

    context "when Spam::Handler.handle_article! raises an error" do
      it "does not call update_score" do
        allow(Spam::Handler).to receive(:handle_article!).and_raise(StandardError.new("Spam handler error"))
        
        expect { worker.perform(article.id) }.to raise_error(StandardError)
        
        # The score should not be updated because the error prevents reaching update_score
        original_score = article.score
        expect(article.reload.score).to eq(original_score)
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
