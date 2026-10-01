require "rails_helper"

RSpec.describe "Organization membership and article privileges" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  def membership(type_of_user, member: user)
    create(:organization_membership, user: member, organization: organization, type_of_user: type_of_user)
  end

  def create_article(params)
    post articles_path, params: { article: params }
  end

  describe "the editor organization list" do
    before { sign_in user }

    it "omits an organization the user is only invited to" do
      membership("pending")

      get new_path

      expect(assigns(:organizations)).not_to include(organization)
    end

    it "includes an organization the user is a member of" do
      membership("member")

      get new_path

      expect(assigns(:organizations)).to include(organization)
    end
  end

  describe "posting under an organization" do
    before { sign_in user }

    it "refuses to attach the organization while the invite is pending" do
      membership("pending")

      expect do
        create_article(title: "Title", body_markdown: "Body", organization_id: organization.id)
      end.to change(Article, :count).by(1)

      expect(user.articles.last.organization_id).to be_nil
    end

    it "attaches the organization for an accepted member" do
      membership("member")

      expect do
        create_article(title: "Title", body_markdown: "Body", organization_id: organization.id)
      end.to change(Article, :count).by(1)

      expect(user.articles.last.organization_id).to eq(organization.id)
    end
  end

  describe "reassigning an article to another author" do
    let(:org_admin) { create(:user) }
    let(:invitee) { create(:user) }
    let(:article) { create(:article, user: org_admin, organization: organization) }

    before do
      membership("admin", member: org_admin)
      sign_in org_admin
    end

    it "refuses an author whose invite is still pending" do
      membership("pending", member: invitee)

      put article_path(article.id), params: { article: { user_id: invitee.id } }

      expect(article.reload.user_id).to eq(org_admin.id)
    end

    it "allows an author who is a member" do
      membership("member", member: invitee)

      put article_path(article.id), params: { article: { user_id: invitee.id } }

      expect(article.reload.user_id).to eq(invitee.id)
    end
  end

  describe "the API" do
    let(:api_secret) { create(:api_secret, user: user) }
    let(:headers) { { "api-key" => api_secret.secret, "content-type" => "application/json" } }

    it "refuses to attach the organization on create while the invite is pending" do
      membership("pending")

      post api_articles_path,
           params: { article: { title: "Title", body_markdown: "Body", organization_id: organization.id } }.to_json,
           headers: headers

      expect(Article.last&.organization_id).to be_nil
    end

    it "attaches the organization on create for an accepted member" do
      membership("member")

      post api_articles_path,
           params: { article: { title: "Title", body_markdown: "Body", organization_id: organization.id } }.to_json,
           headers: headers

      expect(Article.last&.organization_id).to eq(organization.id)
    end

    it "refuses to attach the organization on update while the invite is pending" do
      membership("pending")
      article = create(:article, user: user)

      put api_article_path(article.id),
          params: { article: { organization_id: organization.id } }.to_json,
          headers: headers

      expect(article.reload.organization_id).to be_nil
    end

    it "attaches the organization on update for an accepted member" do
      membership("member")
      article = create(:article, user: user)

      put api_article_path(article.id),
          params: { article: { organization_id: organization.id } }.to_json,
          headers: headers

      expect(article.reload.organization_id).to eq(organization.id)
    end
  end

  # `guest` is excluded from the `member` scope that backs User#org_member?, so it is
  # treated as a non-posting role here. See the PR description for the reasoning.
  describe "a guest member" do
    before { sign_in user }

    it "is not offered the organization in the editor" do
      membership("guest")

      get new_path

      expect(assigns(:organizations)).not_to include(organization)
    end

    it "cannot attach the organization to a post" do
      membership("guest")

      create_article(title: "Title", body_markdown: "Body", organization_id: organization.id)

      expect(user.articles.last&.organization_id).to be_nil
    end
  end
end
