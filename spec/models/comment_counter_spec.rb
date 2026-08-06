require "rails_helper"

RSpec.describe Comment do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let!(:comment) { create(:comment, user: user, commentable: article) }

  describe "counter cache behavior" do
    it "decrements the commentable comments_count when a comment is destroyed" do
      expect do
        comment.destroy
      end.to change { article.reload.comments_count }.by(-1)
    end

    it "decrements when a comment is soft-deleted" do
      expect do
        comment.update!(deleted: true)
      end.to change { article.reload.comments_count }.by(-1)
    end

    it "increments back when a comment is restored" do
      comment.update!(deleted: true)

      expect do
        comment.update!(deleted: false)
      end.to change { article.reload.comments_count }.by(1)
    end

    it "ignores already deleted comments when destroyed" do
      comment.update!(deleted: true)

      expect do
        comment.destroy
      end.not_to change { article.reload.comments_count }
    end
  end
end
