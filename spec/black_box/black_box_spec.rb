require "rails_helper"

RSpec.describe BlackBox do
  describe "#article_hotness_score" do
    let!(:article) { create(:article) }
    let!(:function_caller) { double }

    it "calls function caller" do
      allow(function_caller).to receive(:call).and_return(5)
      described_class.article_hotness_score(article, function_caller)
      expect(function_caller).to have_received(:call).once
    end

    it "doesn't fail when function caller returns nil" do
      allow(function_caller).to receive(:call).and_return(nil)
      described_class.article_hotness_score(article, function_caller)
      # expect(score).to eq(0)
    end
  end
end
