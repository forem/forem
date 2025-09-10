require "rails_helper"

RSpec.describe Ai::ArticleEnhancer, type: :service do
  let(:user) { create(:user, :trusted) }
  let(:article) { create(:article, user: user, title: "How to Build Amazing Apps", with_tags: false) }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
  end

  describe "#calculate_clickbait_score" do
    context "when AI responds with a valid score" do
      before do
        allow(ai_client).to receive(:call).and_return("0.3")
      end

      it "returns the correct clickbait score" do
        result = described_class.new(article).calculate_clickbait_score
        expect(result).to eq(0.3)
      end
    end

    context "when AI responds with score above 1.0" do
      before do
        allow(ai_client).to receive(:call).and_return("1.5")
      end

      it "caps the score at 1.0" do
        result = described_class.new(article).calculate_clickbait_score
        expect(result).to eq(1.0)
      end
    end

    context "when AI responds with score below 0.0" do
      before do
        allow(ai_client).to receive(:call).and_return("-0.2")
      end

      it "floors the score at 0.0" do
        result = described_class.new(article).calculate_clickbait_score
        expect(result).to eq(0.0)
      end
    end

    context "when AI responds with non-numeric value" do
      before do
        allow(ai_client).to receive(:call).and_return("not a number")
      end

      it "returns 0.0 as default" do
        result = described_class.new(article).calculate_clickbait_score
        expect(result).to eq(0.0)
      end
    end

    context "when AI raises an error" do
      before do
        allow(ai_client).to receive(:call).and_raise(StandardError, "API Error")
      end

      it "returns 0.0 as fallback after retries" do
        result = described_class.new(article).calculate_clickbait_score
        expect(result).to eq(0.0)
      end

      it "retries once before falling back" do
        described_class.new(article).calculate_clickbait_score
        expect(ai_client).to have_received(:call).exactly(2).times
      end

      it "logs retry attempts and final fallback" do
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)
        
        described_class.new(article).calculate_clickbait_score
        
        expect(Rails.logger).to have_received(:error).with(/Clickbait score calculation failed \(attempt 1\/2\)/)
        expect(Rails.logger).to have_received(:info).with(/Retrying clickbait score calculation \(attempt 2\/2\)/)
        expect(Rails.logger).to have_received(:error).with(/Clickbait score calculation failed after 2 attempts/)
      end
    end
  end

  describe "#generate_tags" do
    let!(:javascript_tag) { create(:tag, name: "javascript", supported: true, hotness_score: 100, short_summary: "JavaScript programming language") }
    let!(:webdev_tag) { create(:tag, name: "webdev", supported: true, hotness_score: 90, short_summary: "Web development topics") }
    let!(:react_tag) { create(:tag, name: "react", supported: true, hotness_score: 80, short_summary: "React JavaScript library") }

    context "when article has no tags and candidate tags exist" do
      let(:enhancer) { described_class.new(article) }
      
      before do
        # Mock the get_candidate_tags method directly
        allow(enhancer).to receive(:get_candidate_tags).and_return([javascript_tag, webdev_tag, react_tag])
        
        # Mock the two AI calls for the two-pass approach
        allow(ai_client).to receive(:call)
          .and_return("javascript,webdev,react", "javascript,webdev")
      end

      it "returns suggested tags from two-pass selection" do
        result = enhancer.generate_tags
        expect(result).to eq(["javascript", "webdev"])
      end

      it "calls AI twice for two-pass selection" do
        enhancer.generate_tags
        expect(ai_client).to have_received(:call).exactly(2).times
      end
    end

    context "when article already has tags" do
      before do
        article.update(cached_tag_list: "existing,tags")
        allow(ai_client).to receive(:call)
      end

      it "returns empty array without calling AI" do
        result = described_class.new(article).generate_tags
        expect(result).to eq([])
        expect(ai_client).not_to have_received(:call)
      end
    end

    context "when no candidate tags exist" do
      let(:enhancer) { described_class.new(article) }
      
      before do
        # Mock get_candidate_tags to return empty result
        allow(enhancer).to receive(:get_candidate_tags).and_return([])
        allow(ai_client).to receive(:call)
      end

      it "returns empty array without calling AI" do
        result = enhancer.generate_tags
        expect(result).to eq([])
        expect(ai_client).not_to have_received(:call)
      end
    end

    context "when first pass returns no valid tags" do
      let(:enhancer) { described_class.new(article) }
      
      before do
        allow(enhancer).to receive(:get_candidate_tags).and_return([javascript_tag, webdev_tag])
        # AI returns tags that don't match our candidate tags
        allow(ai_client).to receive(:call).and_return("invalidtag,anotherbadtag")
      end

      it "returns empty array after first pass" do
        result = enhancer.generate_tags
        expect(result).to eq([])
        expect(ai_client).to have_received(:call).once
      end
    end

    context "when AI raises an error" do
      let(:enhancer) { described_class.new(article) }
      
      before do
        allow(enhancer).to receive(:get_candidate_tags).and_return([javascript_tag, webdev_tag])
        allow(ai_client).to receive(:call).and_raise(StandardError, "API Error")
      end

      it "returns empty array as fallback after retries" do
        result = enhancer.generate_tags
        expect(result).to eq([])
      end

      it "retries once before falling back" do
        enhancer.generate_tags
        expect(ai_client).to have_received(:call).exactly(2).times
      end

      it "logs retry attempts and final fallback" do
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)
        
        enhancer.generate_tags
        
        expect(Rails.logger).to have_received(:error).with(/Tag generation failed \(attempt 1\/2\)/)
        expect(Rails.logger).to have_received(:info).with(/Retrying tag generation \(attempt 2\/2\)/)
        expect(Rails.logger).to have_received(:error).with(/Tag generation failed after 2 attempts/)
      end
    end
  end
end