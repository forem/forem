require "rails_helper"

RSpec.describe "Reactions", type: :request do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, commentable_id: article.id) }
  let(:max_age) { FastlyRails.configuration.max_age }
  let(:stale_if_error) { FastlyRails.configuration.stale_if_error }

  describe "GET /reactions?article_id=:article_id" do
    context "when signed in" do
      before do
        sign_in user
        get "/reactions?article_id=#{article.id}"
      end

      it "returns reactions count for article" do
        expect(response.body).to include("article_reaction_counts")
      end

      it "does not set cache control headers" do
        expect(response.headers["Surrogate-Key"]).to eq(nil)
      end

      it "does not set Fastly cache control and surrogate control headers" do
        expect(response.headers.to_hash).not_to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when signed out" do
      before { get "/reactions?article_id=#{article.id}" }

      it "returns reactions count for article" do
        expect(response.body).to include("article_reaction_counts")
      end

      it "sets the surrogate key header equal to params for article" do
        expect(response.headers["Surrogate-Key"]).to eq(controller.params.to_s)
      end

      it "sets Fastly cache control and surrogate control headers" do
        expect(response.headers.to_hash).to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end
  end

  describe "GET /reactions?commentable_id=:article.id&commentable_type=Comment" do
    context "when signed in" do
      before do
        sign_in user
        get "/reactions?commentable_id=#{article.id}&commentable_type=Comment"
      end

      it "returns positive reaction counts" do
        expect(response.body).to include("positive_reaction_counts")
      end

      it "does not set surrogate key headers" do
        expect(response.headers["Surrogate-Key"]).to eq(nil)
      end

      it "does not set Fastly cache control and surrogate control headers" do
        expect(response.headers.to_hash).not_to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when signed out" do
      before { get "/reactions?commentable_id=#{article.id}&commentable_type=Comment" }

      it "returns positive reaction counts" do
        expect(response.body).to include("positive_reaction_counts")
      end

      it "sets the surrogate key header equal to params" do
        expect(response.headers["Surrogate-Key"]).to eq(controller.params.to_s)
      end

      it "sets Fastly cache control and surrogate control headers" do
        expect(response.headers.to_hash).to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end
  end

  describe "POST /reactions" do
    let(:valid_params) do
      {
        reactable_id: article.id,
        reactable_type: "Article",
        category: "like"
      }
    end

    before do
      sign_in user
      post "/reactions", params: valid_params
    end

    it "creates reaction" do
      expect(Reaction.last.reactable_id).to eq(article.id)
    end

    it "destroys existing reaction" do
      # same route to destroy, so sending POST request again
      post "/reactions", params: valid_params
      expect(Reaction.all.size).to eq(0)
    end
  end
end
