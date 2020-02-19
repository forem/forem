require "rails_helper"

RSpec.describe CommentDecorator, type: :decorator do
  context "with serialization" do
    let_it_be_readonly(:comment) { create(:comment).decorate }

    it "serializes both the decorated object IDs and decorated methods" do
      expected_result = { "id" => comment.id, "published_timestamp" => comment.published_timestamp }
      expect(comment.as_json(only: [:id], methods: [:published_timestamp])).to eq(expected_result)
    end

    it "serializes collections of decorated objects" do
      decorated_collection = Comment.decorate
      expected_result = [{ "id" => comment.id, "published_timestamp" => comment.published_timestamp }]
      expect(decorated_collection.as_json(only: [:id], methods: [:published_timestamp])).to eq(expected_result)
    end
  end

  describe "#low_quality" do
    let(:threshold) { CommentDecorator::LOW_QUALITY_THRESHOLD }
    let(:comment) { build(:comment) }

    it "returns true if the comment is low quality" do
      comment.score = threshold - 1
      expect(comment.decorate.low_quality).to be(true)
    end

    it "returns false if the comment score is on threshold quality" do
      comment.score = threshold
      expect(comment.decorate.low_quality).to be(false)
    end

    it "returns false if the comment is a good quality" do
      comment.score = threshold + 1
      expect(comment.decorate.low_quality).to be(false)
    end
  end

  describe "#published_timestamp" do
    it "returns empty string if the comment is new" do
      expect(Comment.new.decorate.published_timestamp).to eq("")
    end

    it "returns the timestamp of the creation date" do
      comment = build_stubbed(:comment).decorate
      expect(comment.published_timestamp).to eq(comment.created_at.utc.iso8601)
    end
  end
end
