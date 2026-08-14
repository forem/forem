require "rails_helper"

RSpec.describe Articles::GenerateSummaryWorker, type: :worker do
  describe "#perform" do
    let(:article) { create(:article) }
    let(:generator_instance) { instance_double(Ai::ArticleSummaryGenerator, call: true) }

    before do
      stub_const("Ai::Base::DEFAULT_KEY", "some_key")
      allow(Ai::ArticleSummaryGenerator).to receive(:new).with(article).and_return(generator_instance)
    end

    it "bails if Ai::Base::DEFAULT_KEY is not present" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)
      expect(Ai::ArticleSummaryGenerator).not_to receive(:new)
      described_class.new.perform(article.id)
    end

    it "bails if article is not found" do
      expect(Ai::ArticleSummaryGenerator).not_to receive(:new)
      described_class.new.perform(0)
    end

    it "bails if score is less than 50" do
      article.update_columns(score: 49, comment_score: 25)

      described_class.new.perform(article.id)
      expect(generator_instance).not_to have_received(:call)
    end

    it "bails if comment_score is less than 25" do
      article.update_columns(score: 50, comment_score: 24)

      described_class.new.perform(article.id)
      expect(generator_instance).not_to have_received(:call)
    end

    it "calls the generator when conditions are met" do
      article.update_columns(score: 50, comment_score: 25)

      described_class.new.perform(article.id)
      expect(generator_instance).to have_received(:call)
    end
  end
end
