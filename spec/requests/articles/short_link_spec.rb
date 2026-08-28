require "rails_helper"

RSpec.describe "Article Short Links" do
  let(:article) { create(:article, published: true) }
  let(:short_code) { article.id.to_s(26).reverse }

  context "when the article exists and is published" do
    it "redirects to the article path" do
      get "/a/#{short_code}"

      expect(response).to redirect_to(article.path)
      expect(response).to have_http_status(:found)
    end

    it "handles case insensitivity" do
      get "/a/#{short_code.upcase}"

      expect(response).to redirect_to(article.path)
      expect(response).to have_http_status(:found)
    end

    context "with caching headers" do
      before { get "/a/#{short_code}" }

      it "sets Fastly Cache-Control headers" do
        expect(response.headers["Cache-Control"]).to eq("public, no-cache")
      end

      it "sets Fastly Surrogate-Key headers" do
        expect(response.headers["Surrogate-Key"]).to eq("articles/#{article.id}")
      end
    end
  end

  context "when the article is unpublished" do
    let(:unpublished_article) { create(:article, published: false) }
    let(:unpublished_code) { unpublished_article.id.to_s(26).reverse }

    it "raises record not found error" do
      expect {
        get "/a/#{unpublished_code}"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when the article does not exist" do
    it "raises record not found error" do
      expect {
        get "/a/nonexistentcode"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
