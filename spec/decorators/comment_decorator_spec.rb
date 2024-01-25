require "rails_helper"

RSpec.describe CommentDecorator, type: :decorator do
  context "with serialization" do
    let!(:comment) { create(:comment).decorate }

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
    let(:threshold) { Comment::LOW_QUALITY_THRESHOLD }
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

  describe "#published_at_int" do
    let(:comment) { create(:comment) }

    it "returns the creation date as an integer" do
      expect(comment.created_at).not_to be_nil
      expect(comment.decorate.published_at_int).to eq(comment.created_at.to_i)
    end
  end
end
