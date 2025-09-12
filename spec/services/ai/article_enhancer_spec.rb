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

        expect(Rails.logger).to have_received(:error).with(%r{Clickbait score calculation failed \(attempt 1/2\)})
        expect(Rails.logger).to have_received(:info).with(%r{Retrying clickbait score calculation \(attempt 2/2\)})
        expect(Rails.logger).to have_received(:error).with(/Clickbait score calculation failed after 2 attempts/)
      end
    end
  end

  describe "#generate_tags" do
    let!(:javascript_tag) do
      create(:tag, name: "javascript", supported: true, hotness_score: 100,
                   short_summary: "JavaScript programming language")
    end
    let!(:webdev_tag) do
      create(:tag, name: "webdev", supported: true, hotness_score: 90, short_summary: "Web development topics")
    end
    let!(:react_tag) do
      create(:tag, name: "react", supported: true, hotness_score: 80, short_summary: "React JavaScript library")
    end

    context "when article has no tags and candidate tags exist" do
      let(:enhancer) { described_class.new(article, ai_client: ai_client) }

      before do
        # Mock the get_candidate_tags method to return the actual tags from the database
        allow(enhancer).to receive(:get_candidate_tags).and_return(Tag.where(name: %w[javascript webdev react]))

        # Mock the two AI calls for the two-pass approach
        allow(ai_client).to receive(:call)
          .and_return("javascript,webdev,react", "javascript,webdev")
      end

      it "returns suggested tags from two-pass selection" do
        result = enhancer.generate_tags
        expect(result).to eq(%w[javascript webdev])
      end

      it "calls AI twice for two-pass selection" do
        enhancer.generate_tags
        expect(ai_client).to have_received(:call).exactly(2).times
      end
    end

    context "when article already has tags" do
      let(:article_with_tags) { create(:article, user: user, title: "How to Build Amazing Apps", with_tags: false) }

      before do
        article_with_tags.update_column(:cached_tag_list, "existing,tags")
        allow(ai_client).to receive(:call)
      end

      it "returns empty array without calling AI" do
        result = described_class.new(article_with_tags.reload, ai_client: ai_client).generate_tags
        expect(result).to eq([])
        expect(ai_client).not_to have_received(:call)
      end
    end

    context "when no candidate tags exist" do
      let(:enhancer) { described_class.new(article, ai_client: ai_client) }

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
      it "returns empty array after first pass" do
        # Create a fresh AI client for this test
        test_ai_client = instance_double(Ai::Base)
        enhancer = described_class.new(article, ai_client: test_ai_client)

        # Return an ActiveRecord relation instead of an array
        allow(enhancer).to receive(:get_candidate_tags).and_return(Tag.where(name: %w[javascript webdev]))
        # AI returns tags that don't match our candidate tags
        allow(test_ai_client).to receive(:call).and_return("invalidtag,anotherbadtag")

        result = enhancer.generate_tags
        expect(result).to eq([])
        expect(test_ai_client).to have_received(:call).once
      end
    end

    context "when AI raises an error" do
      let(:enhancer) { described_class.new(article, ai_client: ai_client) }

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

        expect(Rails.logger).to have_received(:error).with(%r{Tag generation failed \(attempt 1/2\)})
        expect(Rails.logger).to have_received(:info).with(%r{Retrying tag generation \(attempt 2/2\)})
        expect(Rails.logger).to have_received(:error).with(/Tag generation failed after 2 attempts/)
      end
    end
  end
end
