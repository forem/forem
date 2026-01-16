require "rails_helper"

RSpec.describe Ai::BadgeCriteriaAssessor do
  subject(:assessor) { described_class.new(article, criteria: criteria) }

  let(:article) { create(:published_article) }
  let(:criteria) { "well-researched technical content" }

  describe "#qualifies?" do
    context "when AI returns YES" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("YES")
      end

      it "returns true" do
        expect(assessor.qualifies?).to be(true)
      end
    end

    context "when AI returns NO" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("NO")
      end

      it "returns false" do
        expect(assessor.qualifies?).to be(false)
      end
    end

    context "when AI returns yes (lowercase)" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("yes")
      end

      it "returns true" do
        expect(assessor.qualifies?).to be(true)
      end
    end

    context "when AI returns a response containing YES" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("Based on my analysis, YES, this article qualifies.")
      end

      it "returns true" do
        expect(assessor.qualifies?).to be(true)
      end
    end

    context "when AI raises an error" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_raise(StandardError, "API error")
        allow(Rails.logger).to receive(:error)
      end

      it "returns false" do
        expect(assessor.qualifies?).to be(false)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Badge Criteria Assessment failed/)
        assessor.qualifies?
      end
    end
  end
end
