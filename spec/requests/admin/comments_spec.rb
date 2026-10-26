require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/comments" do
  it_behaves_like "an InternalPolicy dependant request", Comment do
    let(:request) { get admin_comments_path }
  end

  describe "support admin access" do
    let(:comment) { create(:comment, commentable: create(:article)) }

    context "when the user is a support admin" do
      before { sign_in create(:user, :support_admin) }

      it "allows access to the comments index" do
        get admin_comments_path
        expect(response).to have_http_status(:success)
      end

      it "allows access to an individual comment" do
        get admin_comment_path(comment.id)
        expect(response).to have_http_status(:success)
      end

      it "does not allow unfavoriting a comment" do
        expect do
          delete unfavorite_admin_comment_path(comment.id)
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the user has no admin role", :proper_status do
      before { sign_in create(:user) }

      it "does not allow access to an individual comment" do
        get admin_comment_path(comment.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
