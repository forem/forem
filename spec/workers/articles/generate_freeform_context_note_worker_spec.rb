require "rails_helper"

RSpec.describe Articles::GenerateFreeformContextNoteWorker, type: :worker do
  describe "#perform" do
    let(:article) { create(:article) }
    let(:generator_instance) { instance_double(Ai::FreeformContextNoteGenerator, call: true) }

    before do
      stub_const("Ai::Base::DEFAULT_KEY", "some_key")
      allow(Ai::FreeformContextNoteGenerator).to receive(:new).with(article).and_return(generator_instance)
    end

    it "bails if Ai::Base::DEFAULT_KEY is not present" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)
      expect(Ai::FreeformContextNoteGenerator).not_to receive(:new)
      described_class.new.perform(article.id)
    end

    it "bails if article is not found" do
      expect(Ai::FreeformContextNoteGenerator).not_to receive(:new)
      described_class.new.perform(0)
    end

    it "bails if score is less than 50" do
      article.update_column(:score, 49)
      article.update_column(:comment_score, 25)
      
      described_class.new.perform(article.id)
      expect(generator_instance).not_to have_received(:call)
    end

    it "bails if comment_score is less than 25" do
      article.update_column(:score, 50)
      article.update_column(:comment_score, 24)
      article.update_column(:published_at, 1.day.ago)
      
      described_class.new.perform(article.id)
      expect(generator_instance).not_to have_received(:call)
    end

    it "bails if article was published more than a week ago" do
      article.update_column(:score, 50)
      article.update_column(:comment_score, 25)
      article.update_column(:published_at, 8.days.ago)
      
      described_class.new.perform(article.id)
      expect(generator_instance).not_to have_received(:call)
    end

    it "bails if article already has context notes" do
      article.update_column(:score, 50)
      article.update_column(:comment_score, 25)
      article.update_column(:published_at, 1.day.ago)
      create(:context_note, article: article, body_markdown: "existing note")
      
      described_class.new.perform(article.id)
      expect(generator_instance).not_to have_received(:call)
    end

    it "calls the generator when conditions are met" do
      article.update_column(:score, 50)
      article.update_column(:comment_score, 25)
      article.update_column(:published_at, 1.day.ago)
      
      described_class.new.perform(article.id)
      expect(generator_instance).to have_received(:call)
    end
  end
end
