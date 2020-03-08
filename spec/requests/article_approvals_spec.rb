require "rails_helper"

RSpec.describe "ArticleApprovals", type: :request do
  describe "POST article_approvals" do
    let(:tag)            { create(:tag) }
    let(:user)           { create(:user) }
    let(:article)        { create(:article, tags: tag.name) }

    context "when user is not tag mod" do
      before do
        sign_in user
      end

      it "does not allow update" do
        expect { post "/article_approvals", params: { approved: true, id: article.id } }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is a tag mod" do
      before do
        user.add_role(:tag_moderator, tag)
        user.add_role(:trusted)
        sign_in user
      end

      it "does allow update" do
        post "/article_approvals", params: { approved: true, id: article.id }
        expect(article.reload.approved).to eq(true)
      end
    end

    context "when user is admin" do
      before do
        user.add_role(:admin)
        sign_in user
      end

      it "does allow update" do
        post "/article_approvals", params: { approved: true, id: article.id }
        expect(article.reload.approved).to eq(true)
      end
    end
  end
end
