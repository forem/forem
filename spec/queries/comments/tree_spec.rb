require "rails_helper"

RSpec.describe Comments::Tree do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: article) }
  let!(:other_comment) { create(:comment, commentable: article, user: user, created_at: 1.hour.from_now) }
  let!(:child_comment) { create(:comment, commentable: article, parent: comment, user: user) }

  before { comment.update_column(:score, 1) }

  describe "#for_commentable" do
    it "returns a full tree" do
      comments = described_class.for_commentable(article)
      expect(comments).to eq(comment => { child_comment => {} }, other_comment => {})
    end

    it "returns part of the tree" do
      comments = described_class.for_commentable(article, limit: 1)
      expect(comments).to eq(comment => { child_comment => {} })
    end

    context "with include_negative" do
      before do
        other_comment.update_column(:score, -10)
      end

      it "returns comments with low score if include_negative is passed" do
        comments = described_class.for_commentable(article, include_negative: true)
        expect(comments).to eq({ comment => { child_comment => {} }, other_comment => {} })
      end

      it "doesn't return comments with low score if include_negative is false" do
        comments = described_class.for_commentable(article)
        expect(comments).to eq(comment => { child_comment => {} })
      end
    end

    context "with sort order" do
      let!(:new_comment) { create(:comment, commentable: article, user: user, created_at: Date.tomorrow) }
      let!(:old_comment) { create(:comment, commentable: article, user: user, created_at: Date.yesterday) }

      before { comment }

      it "returns comments in the right order when order is oldest" do
        comments = described_class.for_commentable(article, limit: 0, order: "oldest")
        comments = comments.map { |key, _| key.id }
        expect(comments).to contain_exactly(old_comment.id, comment.id, other_comment.id, new_comment.id)
      end

      it "returns comments in the right order when order is latest" do
        comments = described_class.for_commentable(article, limit: 0, order: "latest")
        comments = comments.map { |key, _| key.id }
        expect(comments).to contain_exactly(new_comment.id, other_comment.id, comment.id, old_comment.id)
      end

      it "returns comments in the right order when order is top" do
        comment.update_column(:score, 5)
        highest_rated_comment = comment
        new_comment.update_column(:score, 1)
        lowest_rated_comment = new_comment
        old_comment.update_column(:score, 3)
        mid_high_rated_comment = old_comment
        other_comment.update_column(:score, 2)
        mid_low_rated_comment = other_comment
        comments = described_class.for_commentable(article, limit: 0)

        comments = comments.map { |key, _| key.id }
        expect(comments).to eq([highest_rated_comment.id, mid_high_rated_comment.id, mid_low_rated_comment.id, lowest_rated_comment.id]) # rubocop:disable Layout/LineLength
      end
    end
  end

  describe "#for_root_comment" do
    let!(:low_comment) { create(:comment, commentable: article, parent: comment, score: -100) }

    it "returns tree for a particular comment" do
      comments = described_class.for_root_comment(comment)
      expect(comments).to eq(comment => { child_comment => {} })
    end

    it "returns tree with negative comments" do
      comments = described_class.for_root_comment(comment, include_negative: true)
      expect(comments).to eq(comment => { child_comment => {}, low_comment => {} })
    end
  end
end
