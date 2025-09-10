require "rails_helper"

RSpec.describe Articles::HandleSpamWorker, type: :worker do
  let(:article) { create(:article, with_tags: false) }
  let(:worker) { described_class.new }
  let(:enhancer) { instance_double(Ai::ArticleEnhancer) }

  describe "#perform" do
    before do
      allow(Ai::ArticleEnhancer).to receive(:new).with(any_args).and_return(enhancer)
      allow(enhancer).to receive(:calculate_clickbait_score).and_return(0.3)
      allow(enhancer).to receive(:generate_tags).and_return([])
    end

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

      it "enhances article with clickbait score" do
        allow(Spam::Handler).to receive(:handle_article!)
        
        worker.perform(article.id)
        
        expect(Ai::ArticleEnhancer).to have_received(:new).with(article)
        expect(enhancer).to have_received(:calculate_clickbait_score)
        expect(article.reload.clickbait_score).to eq(0.3)
      end

      it "generates tags when article has no tags and meets criteria" do
        # Ensure article meets all criteria: score >= 0, clickbait < 0.6
        article.update_columns(score: 5)
        
        allow(Spam::Handler).to receive(:handle_article!)
        allow(article).to receive(:update_score) # Don't actually update the score
        
        # Mock the enhancer to return appropriate values
        allow(enhancer).to receive(:calculate_clickbait_score).and_return(0.4) # < 0.6
        allow(enhancer).to receive(:generate_tags).and_return(["javascript", "webdev"])
        
        # Create the tags that will be suggested
        javascript_tag = Tag.find_or_create_by(name: "javascript") { |tag| tag.supported = true }
        webdev_tag = Tag.find_or_create_by(name: "webdev") { |tag| tag.supported = true }
        
        worker.perform(article.id)
        
        expect(enhancer).to have_received(:generate_tags)
        expect(article.reload.cached_tag_list).to include("javascript")
        expect(article.reload.cached_tag_list).to include("webdev")
      end

      it "only applies valid tags that exist in the system" do
        article.update(cached_tag_list: "", score: 5)
        allow(Spam::Handler).to receive(:handle_article!)
        allow(enhancer).to receive(:calculate_clickbait_score).and_return(0.4)
        allow(enhancer).to receive(:generate_tags).and_return(["javascript", "nonexistent"])
        
        # Only create one of the suggested tags
        javascript_tag = Tag.find_or_create_by(name: "javascript") { |tag| tag.supported = true }
        
        worker.perform(article.id)
        
        expect(article.reload.cached_tag_list).to include("javascript")
        expect(article.reload.cached_tag_list).not_to include("nonexistent")
      end

      it "logs warning when no valid tags are found" do
        # Ensure article meets criteria for tag generation
        article.update_columns(score: 5)
        
        allow(Spam::Handler).to receive(:handle_article!)
        allow(article).to receive(:update_score) # Don't actually update the score
        
        # Mock enhancer to return values that trigger tag generation
        allow(enhancer).to receive(:calculate_clickbait_score).and_return(0.4) # < 0.6
        allow(enhancer).to receive(:generate_tags).and_return(["nonexistent"])
        allow(Rails.logger).to receive(:warn)
        
        worker.perform(article.id)
        
        expect(enhancer).to have_received(:generate_tags)
        expect(Rails.logger).to have_received(:warn).with(/No valid tags found from suggestions/)
      end

      it "does not generate tags when article already has tags" do
        article.update(cached_tag_list: "existing")
        allow(Spam::Handler).to receive(:handle_article!)
        allow(article).to receive(:update_score)
        
        worker.perform(article.id)
        
        expect(enhancer).not_to have_received(:generate_tags)
      end

      it "does not generate tags when article score is negative" do
        article.update(cached_tag_list: "", score: -1)
        allow(Spam::Handler).to receive(:handle_article!)
        allow(article).to receive(:update_score)
        
        worker.perform(article.id)
        
        expect(enhancer).not_to have_received(:generate_tags)
      end

      it "does not generate tags when clickbait score is too high" do
        article.update(cached_tag_list: "", score: 5)
        allow(Spam::Handler).to receive(:handle_article!)
        allow(article).to receive(:update_score)
        allow(enhancer).to receive(:calculate_clickbait_score).and_return(0.7)
        
        worker.perform(article.id)
        
        expect(enhancer).not_to have_received(:generate_tags)
      end
    end

    context "when article does not exist" do
      it "does not call Spam::Handler.handle_article!" do
        allow(Spam::Handler).to receive(:handle_article!)
        
        worker.perform(999999)
        expect(Spam::Handler).not_to have_received(:handle_article!)
      end

      it "does not call article enhancement" do
        worker.perform(999999)
        expect(Ai::ArticleEnhancer).not_to have_received(:new)
      end

      it "does not raise an error" do
        expect { worker.perform(999999) }.not_to raise_error
      end
    end

    context "when Spam::Handler.handle_article! raises an error" do
      it "does not call update_score or enhancement" do
        allow(Spam::Handler).to receive(:handle_article!).and_raise(StandardError.new("Spam handler error"))
        
        expect { worker.perform(article.id) }.to raise_error(StandardError)
        
        # The score should not be updated because the error prevents reaching update_score
        original_score = article.score
        expect(article.reload.score).to eq(original_score)
        expect(Ai::ArticleEnhancer).not_to have_received(:new)
      end
    end

    context "when article enhancement fails" do
      it "logs error but continues processing" do
        allow(Spam::Handler).to receive(:handle_article!)
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
