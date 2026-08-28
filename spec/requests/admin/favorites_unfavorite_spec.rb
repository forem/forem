require "rails_helper"

RSpec.describe "Admin un-favorite" do
  let(:admin) { create(:user, :admin) }
  let(:leader) { create(:user, :community_leader_level_1) }

  before { sign_in admin }

  describe "DELETE /admin/content_manager/articles/:id/unfavorite" do
    it "clears the favorite and redirects" do
      article = create(:article, favorited_by_user: leader, favorited_at: Time.current)

      delete unfavorite_admin_article_path(article.id)

      expect(response).to redirect_to(admin_article_path(article.id))
      expect(article.reload.favorited_by_user_id).to be_nil
    end
  end

  describe "DELETE /admin/content_manager/comments/:id/unfavorite" do
    it "clears the favorite and redirects" do
      comment = create(:comment, favorited_by_user: leader, favorited_at: Time.current)

      delete unfavorite_admin_comment_path(comment.id)

      expect(response).to redirect_to(admin_comment_path(comment.id))
      expect(comment.reload.favorited_by_user_id).to be_nil
    end
  end

  context "when the requester is not an admin" do
    it "is not authorized" do
      sign_in create(:user)
      article = create(:article, favorited_by_user: leader, favorited_at: Time.current)

      expect { delete unfavorite_admin_article_path(article.id) }.to raise_error(Pundit::NotAuthorizedError)
      expect(article.reload.favorited_by_user_id).to eq(leader.id)
    end
  end
end
