require "rails_helper"

RSpec.describe "Reactions", type: :request do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:comment) { create(:comment, commentable: article) }

  let_it_be(:max_age) { FastlyRails.configuration.max_age }
  let_it_be(:stale_if_error) { FastlyRails.configuration.stale_if_error }

  describe "GET /reactions?article_id=:article_id" do
    before do
      create(:reaction, reactable: article, user: user, points: 1)
    end

    context "when signed in" do
      before do
        sign_in user

        get reactions_path(article_id: article.id)
      end

      it "returns the correct json response" do
        result = response.parsed_body

        expect(result["current_user"]).to eq("id" => user.id)
        expected_reactions_counts = [
          { "category" => "like", "count" => 1 },
          { "category" => "readinglist", "count" => 0 },
          { "category" => "unicorn", "count" => 0 },
        ]
        expect(result["article_reaction_counts"]).to eq(expected_reactions_counts)
        expect(result["reactions"].to_json).to eq(user.reactions.where(reactable: article).to_json)
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
      before { get reactions_path(article_id: article.id) }

      it "returns the correct json response" do
        result = response.parsed_body

        expect(result["current_user"]).to eq("id" => nil)
        expected_reactions = [
          { "category" => "like", "count" => 1 },
          { "category" => "readinglist", "count" => 0 },
          { "category" => "unicorn", "count" => 0 },
        ]
        expect(result["article_reaction_counts"]).to eq(expected_reactions)
        expect(result["reactions"]).to be_empty
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

  describe "GET /reactions?commentable_id=:article.id&commentable_type=Article" do
    before do
      create(:reaction, reactable: comment, user: user, points: 1)
    end

    context "when signed in" do
      before do
        sign_in user

        get reactions_path(commentable_id: article.id, commentable_type: "Article")
      end

      it "returns the correct json response" do
        result = response.parsed_body

        expect(result["current_user"]).to eq("id" => user.id)
        expect(result["positive_reaction_counts"]).to eq([{ "id" => article.comments.last.id, "count" => 1 }])
        expect(result["reactions"].to_json).to eq(user.reactions.where(reactable: comment).to_json)
      end

      it "does not set surrogate key headers" do
        expect(response.headers["surrogate-key"]).to be_nil
      end

      it "does not set Fastly cache control and surrogate control headers" do
        expect(response.headers.to_hash).not_to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when signed out" do
      before { get reactions_path(commentable_id: article.id, commentable_type: "Article") }

      it "returns the correct json response" do
        result = response.parsed_body

        expect(result["current_user"]).to eq("id" => nil)
        expect(result["positive_reaction_counts"]).to eq([{ "id" => article.comments.last.id, "count" => 1 }])
        expect(result["reactions"]).to be_empty
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
    let(:trusted_user) { create(:user, :trusted) }
    let(:article_params) do
      {
        reactable_id: article.id,
        reactable_type: "Article",
        category: "like"
      }
    end

    let(:user_params) do
      {
        reactable_id: user.id,
        reactable_type: "User",
        category: "vomit"
      }
    end

    context "when reacting to an article" do
      before do
        sign_in user
        post "/reactions", params: article_params
      end

      it "creates reaction" do
        expect(Reaction.last.reactable_id).to eq(article.id)
      end

      it "destroys existing reaction" do
        # same route to destroy, so sending POST request again
        post "/reactions", params: article_params
        expect(Reaction.all.size).to eq(0)
      end
    end

    context "when creating readinglist" do
      before do
        user.update_column(:experience_level, 8)
        sign_in user
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "readinglist"
        }
      end

      it "creates reaction" do
        expect(Reaction.last.reactable_id).to eq(article.id)
      end

      it "creates rating vote" do
        expect(RatingVote.last.context).to eq("readinglist_reaction")
        expect(RatingVote.last.rating).to be(8.0)
      end
    end

    context "when vomiting on a user" do
      before do
        sign_in trusted_user
        post "/reactions", params: user_params
      end

      it "creates reaction" do
        expect(Reaction.last.reactable_id).to eq(user.id)
      end

      it "destroys existing reaction" do
        # same route to destroy, so sending POST request again
        post "/reactions", params: user_params
        expect(Reaction.all.size).to eq(0)
      end
    end

    context "when signed in as admin" do
      let_it_be(:admin) { create(:user, :admin) }

      before do
        sign_in admin
      end

      it "automatically approves vomits on users" do
        post "/reactions", params: user_params

        reaction = Reaction.find_by(reactable_id: user.id)
        expect(reaction.category).to eq("vomit")
        expect(reaction.status).to eq("confirmed")
      end

      it "automatically approves vomits on articles" do
        post "/reactions", params: article_params.merge(category: "vomit")

        reaction = Reaction.find_by(reactable_id: article.id)
        expect(reaction.category).to eq("vomit")
        expect(reaction.status).to eq("confirmed")
      end
    end

    context "when part of field test" do
      before do
        sign_in user
        allow(Users::RecordFieldTestEventWorker).to receive(:perform_async)
      end

      it "converts field test" do
        post "/reactions", params: article_params
        expect(Users::RecordFieldTestEventWorker).to have_received(:perform_async).with(user.id, :user_home_feed, "user_creates_reaction")
      end
    end
  end
end
