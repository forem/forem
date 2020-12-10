require "rails_helper"

RSpec.shared_examples "an elevated privilege required request" do |path|
  context "when not logged-in" do
    it "does not grant access", proper_status: true do
      get path
      expect(response).to have_http_status(:not_found)
    end

    it "raises Pundit::NotAuthorizedError internally" do
      expect { get path }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when user is not trusted" do
    before { sign_in create(:user) }

    it "does not grant acesss", proper_status: true do
      get path
      expect(response).to have_http_status(:not_found)
    end

    it "internally raise Pundit::NotAuthorized internally" do
      expect { get path }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end

RSpec.describe "Moderations", type: :request do
  let(:trusted_user) { create(:user, :trusted) }
  let(:article) { create(:article) }
  let(:comment) { create(:comment, commentable: article) }
  let(:dev_account) { create(:user) }

  it_behaves_like "an elevated privilege required request", "/username/random-article/mod"
  it_behaves_like "an elevated privilege required request", "/username/comment/1/mod"
  it_behaves_like "an elevated privilege required request", "/username/random-article/actions_panel"

  context "when user is trusted" do
    before do
      sign_in trusted_user
      allow(User).to receive(:dev_account).and_return(dev_account)
    end

    it "grants access to comment moderation" do
      get "#{comment.path}/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grant access to article moderation" do
      get "#{article.path}/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grants access to /mod index" do
      create(:rating_vote, article: article, user: trusted_user)
      get "/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grants access to /mod index with articles" do
      article = create(:article, published: true)
      get "/mod"
      expect(response.body).to include(CGI.escapeHTML(article.title))
    end

    it "grants access to /mod/:tag index with articles" do
      create(:article, published: true)
      get "/mod/#{article.tags.first}"
      expect(response.body).to include("##{article.tags.first.name}")
      expect(response.body).to include(CGI.escapeHTML(article.title))
    end

    it "returns not found for inappropriate tags" do
      expect { get "/mod/dsdsdsweweedsdseweww" }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "renders not_found when an article can't be found" do
      expect do
        get "/#{trusted_user.username}/dsdsdsweweedsdseweww/mod/"
      end.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe "actions_panel" do
    context "when the user is a tag moderator" do
      it "shows the option to remove the tag when the article has the tag" do
        tag_mod = create(:user, :tag_moderator)
        tag_mod.add_role :trusted
        tag = tag_mod.roles.find_by(name: "tag_moderator").resource
        article = create(:article, tags: tag)
        sign_in tag_mod

        get "#{article.path}/actions_panel"
        expect(response.body).to include "circle centered-icon adjustment-icon subtract"
      end
    end

    it "shows the option to add the tag when the article has the tag" do
      tag_mod = create(:user, :tag_moderator)
      tag_mod.add_role :trusted
      article = create(:article, tags: "javascript, cool, beans")
      sign_in tag_mod

      get "#{article.path}/actions_panel"
      expect(response.body).to include "circle centered-icon adjustment-icon plus"
    end
  end

  context "when the user is trusted" do
    before do
      sign_in trusted_user
      get "#{article.path}/actions_panel"
    end

    it "does not show the adjust tags options" do
      expect(response.body).not_to include "other-things-btn adjust-tags"
    end

    it "shows the experience level option" do
      expect(response.body).to include "other-things-btn set-experience"
    end
  end

  context "when the user is an admin" do
    before do
      admin = create(:user, :admin)
      sign_in admin
      article = create(:article, tags: "javascript, cool, beans")
      get "#{article.path}/actions_panel"
    end

    it "shows the admin tag options", :aggregate_failures do
      expect(response.body).to include "admin-add-tag"
      expect(response.body).to include "circle centered-icon adjustment-icon subtract"
    end
  end
end
