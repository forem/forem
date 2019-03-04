require "rails_helper"

RSpec.describe CommentDecorator, type: :decorator do
  describe "#low_quality" do
    let(:threshold) { CommentDecorator::LOW_QUALITY_THRESHOLD }

    it "returns true if the comment is low quality" do
      comment = build_stubbed(:comment, score: threshold - 1).decorate
      expect(comment.low_quality).to be(true)
    end

    it "returns false if the comment score is on threshold quality" do
      comment = build_stubbed(:comment, score: threshold).decorate
      expect(comment.low_quality).to be(false)
    end

    it "returns false if the comment is a good quality" do
      comment = build_stubbed(:comment, score: threshold + 1).decorate
      expect(comment.low_quality).to be(false)
    end
  end
end
