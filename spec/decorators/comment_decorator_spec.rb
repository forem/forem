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

  describe "published_timestamp" do
    it "returns empty string if the comment is new" do
      expect(Comment.new.decorate.published_timestamp).to eq("")
    end

    it "returns the timestamp of the creation date" do
      comment = build_stubbed(:comment).decorate
      expect(comment.published_timestamp).to eq(comment.created_at.utc.iso8601)
    end
  end
end
