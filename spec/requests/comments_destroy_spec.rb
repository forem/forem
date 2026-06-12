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

      it "renders [deleted]" do
        get parent_comment.path
        expect(response.body).to include "[deleted]"
      end
    end

    # Regression tests for https://github.com/forem/forem/issues/23432
    # displayed_comments_count must be recalculated after any deletion so the
    # article heading reflects the correct visible count immediately.
    context "when recalculating displayed_comments_count after deletion" do
      it "decrements displayed_comments_count when a childless comment is hard-deleted" do
        comment = create(:comment, user_id: user.id, commentable: article)
        Comments::Count.call(article, recalculate: true)
        expect { delete "/comments/#{comment.id}" }
          .to change { article.reload.displayed_comments_count }.by(-1)
      end

      it "keeps displayed_comments_count stable when a parent comment is soft-deleted" do
        # Soft-deleted parents with children still render as "[deleted]", so they
        # remain part of the visible thread and the count should not decrease.
        parent = create(:comment, user_id: user.id, commentable: article)
        create(:comment, user_id: user.id, commentable: article, parent_id: parent.id)
        Comments::Count.call(article, recalculate: true)
        initial_count = article.reload.displayed_comments_count
        delete "/comments/#{parent.id}"
        expect(article.reload.displayed_comments_count).to eq(initial_count)
      end
    end
  end
end
