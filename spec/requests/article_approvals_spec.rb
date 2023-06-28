require "rails_helper"

RSpec.describe "ArticleApprovals" do
  describe "POST article_approvals" do
    let(:tag)            { create(:tag, requires_approval: true) }
    let(:user)           { create(:user) }
    let(:article)        { create(:article, tags: tag.name) }

    context "when user is not tag mod" do
      before do
        sign_in user
      end

      it "does not allow update" do
        expect do
          post "/article_approvals", params: { approved: true, id: article.id }
        end.to raise_error(Pundit::NotAuthorizedError)
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
        expect(article.reload.approved).to be(true)
      end

      it "does allow update when any tag requires approval" do
        second_tag = create(:tag, requires_approval: false)
        article = create(:article, tags: [tag.name, second_tag.name])
        post "/article_approvals", params: { approved: true, id: article.id }
        expect(article.reload.approved).to be(true)
      end

      it "does not allow update when multiple tags and none require approval" do
        second_tag = create(:tag, requires_approval: false)
        third_tag = create(:tag, requires_approval: false)
        article = create(:article, tags: [third_tag.name, second_tag.name])
        expect do
          post "/article_approvals", params: { approved: true, id: article.id }
        end.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not allow update with one tag and does not require approval" do
        tag.update_column(:requires_approval, false)
        expect do
          post "/article_approvals", params: { approved: true, id: article.id }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is admin" do
      before do
        user.add_role(:admin)
        sign_in user
      end

      it "does allow update" do
        post "/article_approvals", params: { approved: true, id: article.id }
        expect(article.reload.approved).to be(true)
      end
    end
  end
end
