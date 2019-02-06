require "rails_helper"

RSpec.describe "CommentMutes", type: :request do
  let(:original_commenter)                      { create(:user) }
  let(:other_commenter)                         { create(:user) }
  let(:article)                                 { create(:article) }
  let(:parent_comment_by_og)                    { create(:comment, commentable: article, user: original_commenter) }
  let(:child_of_parent_by_other)              { create(:comment, commentable: article, user: other_commenter, ancestry: parent_comment_by_og.id.to_s) }
  let(:child_of_child_by_og)                { create(:comment, commentable: article, user: original_commenter, ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}") }
  let(:child_of_child_of_child_by_other)  { create(:comment, commentable: article, user: other_commenter, ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}/#{child_of_child_by_og.id}") }
  let(:child_of_child_of_child_by_og)     { create(:comment, commentable: article, user: original_commenter, ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}/#{child_of_child_by_og.id}/#{child_of_child_by_other.id}") }
  let(:child_of_child_by_other)             { create(:comment, commentable: article, user: other_commenter, ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}") }
  let(:child2_of_child_of_child_by_og) { create(:comment, commentable: article, user: original_commenter, ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}/#{child_of_child_by_other.id}") }
  let(:parent_comment_by_other) { create(:comment, commentable: article, user: other_commenter) }

  describe "PATCH /comment_mutes/:id" do
    context "when an article has two parent comments by two different people" do
      before do
        parent_comment_by_og
        parent_comment_by_other
      end

      it "mutes the parent comment" do
        sign_in original_commenter
        patch "/comment_mutes/#{parent_comment_by_og.id}", params: { comment: { receive_notifications: "false" } }
        expect(parent_comment_by_og.reload.receive_notifications).to be false
      end

      it "does not mute the someone else's parent comment" do
        sign_in original_commenter
        patch "/comment_mutes/#{parent_comment_by_og.id}", params: { comment: { receive_notifications: "false" } }
        expect(parent_comment_by_other.reload.receive_notifications).to be true
      end

      it "unmutes the parent comment if already muted" do
        sign_in original_commenter
        parent_comment_by_og.update(receive_notifications: false)
        patch "/comment_mutes/#{parent_comment_by_og.id}", params: { comment: { receive_notifications: "true" } }
        expect(parent_comment_by_og.reload.receive_notifications).to eq true
      end
    end

    context "when an article has a single comment thread with multiple commenters" do
      before do
        child_of_child_of_child_by_og
        child_of_child_of_child_by_other
        child2_of_child_of_child_by_og
        parent_comment_by_other
        sign_in original_commenter
        patch "/comment_mutes/#{parent_comment_by_og.id}", params: { comment: { receive_notifications: "false" } }
      end

      it "mutes all of the original commenter's comments in a single thread" do
        user_ids_of_muted_comments = Comment.where(receive_notifications: false).pluck(:user_id)
        expect(user_ids_of_muted_comments.uniq).to eq [original_commenter.id]
      end

      it "does not mute someone else's comment of a different thread" do
        expect(parent_comment_by_other.receive_notifications).to be true
      end

      it "does not mute the other commenter's comments in the same thread" do
        results = parent_comment_by_og.subtree.where(user: other_commenter).pluck(:receive_notifications)
        expect(results.uniq).to eq [true]
      end
    end
  end
end
