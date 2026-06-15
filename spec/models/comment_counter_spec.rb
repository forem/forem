require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:comment) { create(:comment, user: user, commentable: article) }

  describe "counter cache update on deletion" do
    it "decrements the commentable comments_count when a childless comment is destroyed" do
      expect {
        comment.destroy
      }.to change { article.reload.comments_count }.by(-1)
    end

    it "does NOT decrement the commentable comments_count when a comment with children is marked as deleted" do
      create(:comment, user: user, commentable: article, parent: comment)
      
      expect {
        comment.destroy # This should trigger the 'else' block in CommentsController#destroy
      }.not_to change { article.reload.comments_count }
    end
  end
end
