require "rails_helper"

RSpec.describe "Stories::PinnedArticlesController", type: :request do
  let(:headers) { { 'content-type': "application/json" } }
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:article) { create(:article) }

  describe "#show" do
    context "when unauthorized" do
      it "rejects a requested by an unauthenticated user" do
        get stories_feed_pinned_article_path, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects a requested by an unauthorized user" do
        sign_in user

        expect { get stories_feed_pinned_article_path, headers: headers }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when authorized" do
      before do
        sign_in(admin)
      end

      it "responds with :not_found if there is no pinned article" do
        get stories_feed_pinned_article_path, headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "responds with the expected JSON response" do
        PinnedArticle.set(article)

        get stories_feed_pinned_article_path, headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => article.id,
          "path" => article.path,
          "title" => article.title,
          "pinned_at" => PinnedArticle.updated_at.iso8601,
        )
      end
    end
  end

  describe "#update" do
    context "when unauthorized" do
      it "rejects a requested by an unauthenticated user" do
        put stories_feed_pinned_article_path, params: { id: 1 }.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects a requested by an unauthorized user" do
        sign_in user

        expect do
          put stories_feed_pinned_article_path, params: { id: 1 }.to_json, headers: headers
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when authorized" do
      before do
        sign_in(admin)
      end

      it "responds with :unprocessable_entity if a non integer id is passed" do
        put stories_feed_pinned_article_path, params: { id: "a" }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "responds with :unprocessable_entity if an invalid article id is passed" do
        put stories_feed_pinned_article_path, params: { id: 9999 }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "responds with :unprocessable_entity if a draft article id is passed" do
        article = create(:article, published: false)
        put stories_feed_pinned_article_path, params: { id: article.id }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "responds with :no_content if a valid article id is passed" do
        put stories_feed_pinned_article_path, params: { id: article.id }.to_json, headers: headers

        expect(response).to have_http_status(:no_content)
      end

      it "updates the pinned article", :aggregate_failures do
        put stories_feed_pinned_article_path, params: { id: article.id }.to_json, headers: headers

        expect(PinnedArticle.get).to eq(article)
      end

      it "creates an audit log" do
        Audit::Subscribe.listen(:moderator)

        expect do
          put stories_feed_pinned_article_path, params: { id: article.id }.to_json, headers: headers
        end.to change(AuditLog, :count).by(1)

        Audit::Subscribe.forget(:moderator)
      end
    end
  end

  describe "#destroy" do
    context "when unauthorized" do
      it "rejects a requested by an unauthenticated user" do
        delete stories_feed_pinned_article_path, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects a requested by an unauthorized user" do
        sign_in user

        expect do
          delete stories_feed_pinned_article_path, headers: headers
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when authorized" do
      before do
        sign_in(admin)
      end

      it "succeeds if there is no pinned article" do
        delete stories_feed_pinned_article_path, headers: headers

        expect(response).to have_http_status(:no_content)
      end

      it "removes the pinned article", :aggregate_failures do
        PinnedArticle.set(article)

        delete stories_feed_pinned_article_path, headers: headers

        expect(PinnedArticle.exists?).to be(false)
      end

      it "creates an audit log" do
        Audit::Subscribe.listen(:moderator)

        expect do
          delete stories_feed_pinned_article_path, headers: headers
        end.to change(AuditLog, :count).by(1)

        Audit::Subscribe.forget(:moderator)
      end
    end
  end
end
