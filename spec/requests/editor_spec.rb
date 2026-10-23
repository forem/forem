require "rails_helper"

RSpec.describe "Editor" do
  describe "GET /new" do
    subject(:request_call) { get new_path }

    let(:user) { create(:user) }

    context "when not authenticated" do
      it { is_expected.to eq(200) }
    end

    context "when authenticated and authorized" do
      before { login_as user }

      it "is a successful response" do
        # We have lots of Cypress tests of the behavior of the `/new` page.  Let's make sure we're
        # verifying AuthN/AuthZ things.
        get new_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /:article/edit" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "when not logged-in" do
      it "redirects to /enter" do
        get "/#{user.username}/#{article.slug}/edit"
        expect(response).to redirect_to(new_magic_link_path)
      end
    end

    context "when logged-in" do
      it "render markdown form" do
        sign_in user
        get "/#{user.username}/#{article.slug}/edit"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "co-author invitations in the editor" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }
    let(:edit_path) { "/#{user.username}/#{article.slug}/edit" }

    before { sign_in user }

    it "leaves the picker out while the feature is disabled" do
      get edit_path

      expect(response.body).not_to include("data-co-author-invitations-enabled")
    end

    context "when the feature is enabled" do
      before { FeatureFlag.enable(:co_author_invitations) }

      it "passes the article's invitations to the editor", :aggregate_failures do
        invitation = create(:co_author_invitation, article: article)

        get edit_path

        html = Nokogiri::HTML(response.body)
        main = html.at_css("main#main-content")
        expect(main["data-co-author-invitations-enabled"]).to eq("true")
        expect(main["data-co-author-invitations-max"]).to eq(CoAuthorInvitation::MAX_PER_ARTICLE.to_s)
        expect(JSON.parse(main["data-co-author-invitations"])).to contain_exactly(
          hash_including("id" => invitation.id, "status" => "pending",
                         "user" => hash_including("username" => invitation.user.username)),
        )
      end

      it "shows an empty picker on a new post" do
        get new_path

        main = Nokogiri::HTML(response.body).at_css("main#main-content")
        expect(main["data-co-author-invitations"]).to eq("[]")
      end

      it "leaves the picker out for someone editing another user's post" do
        admin = create(:user, :super_admin)
        sign_in admin

        get edit_path

        expect(response.body).not_to include("data-co-author-invitations-enabled")
      end
    end
  end

  describe "POST /articles/preview" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }
    let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }

    context "when not logged-in" do
      it "redirects to /enter" do
        post "/articles/preview", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged-in" do
      before do
        sign_in user
      end

      it "returns json" do
        post "/articles/preview", headers: headers
        expect(response.media_type).to eq("application/json")
      end

      it "returns successfully with frontmatter" do
        article_body = <<~MARKDOWN
          ---
          ---

          Hello
        MARKDOWN

        post "/articles/preview",
             headers: headers,
             params: { article_body: article_body },
             as: :json

        expect(response).to be_successful
      end
    end
  end
end
