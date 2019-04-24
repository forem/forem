require "rails_helper"

RSpec.describe BlackBox do
  let!(:function_caller) { double }

  describe "#article_hotness_score" do
    let!(:article) { create(:article, published_at: Time.current) }

    it "calls function caller" do
      allow(function_caller).to receive(:call).and_return(5)
      described_class.article_hotness_score(article, function_caller)
      expect(function_caller).to have_received(:call).once
    end

    it "doesn't fail when function caller returns nil" do
      allow(function_caller).to receive(:call).and_return(nil)
      described_class.article_hotness_score(article, function_caller)
    end

    it "returns the correct value" do
      article.update_column(:score, 99)
      allow(function_caller).to receive(:call).and_return(5)
      # recent bonuses (28 + 31 + 80 + 395 + 330 + 330 = 1194)
      # + score (99)
      # + value from the function caller (5)
      score = described_class.article_hotness_score(article, function_caller)
      expect(score).to eq(1298)
    end
  end

  describe "#calculate_spaminess" do
    let(:user) { build(:user) }
    let(:comment) { build(:comment, user: user) }

    before do
      allow(function_caller).to receive(:call).and_return(1)
    end

    it "returns 100 if there is no user" do
      story = instance_double("Comment", user: nil)
      expect(described_class.calculate_spaminess(story, function_caller)).to eq(100)
      expect(function_caller).not_to have_received(:call)
    end

    it "calls the function_caller" do
      described_class.calculate_spaminess(comment, function_caller)
      expect(function_caller).to have_received(:call).with("blackbox-production-spamScore",
                                                           { story: comment, user: user }.to_json).once
    end

    it "returns the value that the caller returns" do
      spaminess = described_class.calculate_spaminess(comment, function_caller)
      expect(spaminess).to eq(1)
    end
  end
end
