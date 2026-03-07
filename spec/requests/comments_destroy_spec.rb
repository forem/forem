require "rails_helper"

RSpec.describe "CommentsDestroy" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  describe "GET /:username/comment/:id_code/delete_confirm" do
    it "renders the confirmation message" do
      comment = create(:comment, user_id: user.id, commentable: article)
      get "#{comment.path}/delete_confirm"
      expect(response.body).to include("Are you sure you want to delete this comment")
    end
  end

  describe "DELETE /comments/:id" do
    context "when comment has no children" do
      it "destroys the comment" do
        comment = create(:comment, user_id: user.id, commentable: article)
        delete "/comments/#{comment.id}"
        expect(Comment.all.size).to eq(0)
      end
    end

    context "when comment has children" do
      let(:parent_comment) { create(:comment, user_id: user.id, commentable: article) }
      let(:child_comment) do
        create(
          :comment,
          user_id: user.id,
          commentable: article,
          parent_id: parent_comment.id,
        )
      end

      before do
        parent_comment
        child_comment
        delete "/comments/#{parent_comment.id}"
      end

      it "marks the comment as deleted" do
        expect(Comment.first.deleted).to be(true)
      end

      it "preserves both comments in the database" do
        expect(Comment.count).to eq(2)
      end

      it "does not delete the child comment" do
        expect(child_comment.reload.deleted).to be(false)
      end

      it "renders [deleted]" do
        get parent_comment.path
        expect(response.body).to include "Comment deleted"
      end

      it "renders the child comment in the thread" do
        get parent_comment.path
        expect(response.body).to include(child_comment.processed_html)
      end
    end
  end

  describe "when user is deleted" do
    context "with comments that have children" do
      let(:commenter) { create(:user) }
      let(:replier) { create(:user) }
      let(:parent_comment) { create(:comment, user: commenter, commentable: article) }
      let(:child_comment) do
        create(:comment, user: replier, commentable: article, parent_id: parent_comment.id)
      end

      before do
        parent_comment
        child_comment
      end

      it "soft-deletes the user's comments" do
        Users::Delete.call(commenter)
        expect(parent_comment.reload.deleted).to be true
      end

      it "preserves both comments in the database" do
        Users::Delete.call(commenter)
        expect(Comment.count).to eq(2)
      end

      it "does not delete child comments" do
        Users::Delete.call(commenter)
        expect(child_comment.reload.deleted).to be false
      end

      it "preserves the thread structure with deleted parent" do
        Users::Delete.call(commenter)
        expect(child_comment.reload.parent_id).to eq parent_comment.id
      end
      it "renders [deleted]" do
        Users::Delete.call(commenter)
        get article.path
        expect(response.body).to include "Comment deleted"
      end

      it "renders the child comment in the thread" do
        Users::Delete.call(commenter)
        get article.path
        expect(response.body).to include(child_comment.processed_html)
      end
    end

    context "with comments that have no children" do
      let(:commenter) { create(:user) }
      let!(:orphan_comment) { create(:comment, user: commenter, commentable: article) }

      it "soft-deletes the user's comment" do
        Users::Delete.call(commenter)
        expect(orphan_comment.reload.deleted).to be true
      end

      it "preserves the comment in the database" do
        initial_count = Comment.count
        Users::Delete.call(commenter)
        expect(Comment.count).to eq(initial_count)
      end

      it "marks the comment as deleted" do
        Users::Delete.call(commenter)
        expect(orphan_comment.reload.deleted).to be true
      end
    end
  end
end
