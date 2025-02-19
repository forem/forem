require "rails_helper"

RSpec.describe "Reactions" do
  let(:user)    { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:comment) { create(:comment, commentable: article) }

  let(:max_age) { 2.weeks.to_i }
  let(:stale_if_error) { 1.day.to_i }

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
          { "category" => "exploding_head", "count" => 0 },
          { "category" => "raised_hands", "count" => 0 },
          { "category" => "fire", "count" => 0 },
        ]
        expect(result["article_reaction_counts"]).to match_array(expected_reactions_counts)
        expect(result["reactions"].to_json).to eq(user.reactions.where(reactable: article).to_json)
      end

      it "does not set Surrogate-Key cache control headers" do
        expect(response.headers["Surrogate-Key"]).to be_nil
      end

      it "does not set X-Accel-Expires headers" do
        expect(response.headers["X-Accel-Expires"]).to be_nil
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
          { "category" => "exploding_head", "count" => 0 },
          { "category" => "raised_hands", "count" => 0 },
          { "category" => "fire", "count" => 0 },
        ]
        expect(result["article_reaction_counts"]).to match_array(expected_reactions)
        expect(result["reactions"]).to be_empty
      end

      it "sets the surrogate key header equal to params for article" do
        expect(response.headers["Surrogate-Key"]).to eq(controller.params.to_s)
      end

      it "sets the x-accel-expires header equal to max-age for article" do
        expect(response.headers["X-Accel-Expires"]).to eq(max_age.to_s)
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
        expect(response.parsed_body).to eq(
          "current_user" => { "id" => user.id },
          "public_reaction_counts" => [{ "id" => article.comments.last.id, "count" => 1 }],
          "reactions" => JSON.parse(user.reactions.where(reactable: comment).to_json),
        )
      end

      it "does not set surrogate key headers" do
        expect(response.headers["surrogate-key"]).to be_nil
      end

      it "does not set x-accel-expires headers" do
        expect(response.headers["x-accel-expires"]).to be_nil
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
        expect(result["public_reaction_counts"]).to eq([{ "id" => article.comments.last.id, "count" => 1 }])
        expect(result["reactions"]).to be_empty
      end

      it "sets the surrogate key header equal to params" do
        expect(response.headers["Surrogate-Key"]).to eq(controller.params.to_s)
      end

      it "sets the x-accel-expires header equal to max-age for article" do
        expect(response.headers["X-Accel-Expires"]).to eq(max_age.to_s)
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

    context "when rate limiting" do
      let(:rate_limiter) { RateLimitChecker.new(user) }

      before do
        allow(RateLimitChecker).to receive(:new).and_return(rate_limiter)
        sign_in user
      end

      it "increments rate limit for reaction_creation" do
        allow(rate_limiter).to receive(:track_limit_by_action)
        post "/reactions", params: article_params

        expect(rate_limiter).to have_received(:track_limit_by_action).with(:reaction_creation)
      end

      it "returns a 429 status when rate limit is reached" do
        allow(rate_limiter).to receive(:limit_by_action).and_return(true)
        post "/reactions", params: article_params

        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "when reacting to an article" do
      before do
        sign_in user
      end

      it "creates reaction" do
        expect do
          post "/reactions", params: article_params
        end.to change(Reaction, :count).by(1)
      end

      it "destroys existing reaction" do
        post "/reactions", params: article_params
        expect do
          # same route to destroy, so sending POST request again
          post "/reactions", params: article_params
        end.to change(Reaction, :count).by(-1)
      end

      it "has success http status" do
        post "/reactions", params: article_params
        expect(response).to be_successful
      end

      it "sends Algolia insight event" do
        # Set up the expectation before making the request
        allow(Settings::General).to receive_messages(algolia_application_id: "test", algolia_api_key: "test")
        algolia_service_instance = instance_double(AlgoliaInsightsService)
        allow(AlgoliaInsightsService).to receive(:new).and_return(algolia_service_instance)
        allow(algolia_service_instance).to receive(:track_event)
        post "/reactions", params: article_params
        expect(algolia_service_instance).to have_received(:track_event).with(
          "conversion",
          "Reaction Created",
          user.id,
          article.id,
          "Article_#{Rails.env}",
          instance_of(Integer),
        )
      end
    end

    context "when creating readinglist" do
      before do
        user.setting.update_column(:experience_level, 8)
        sign_in user
      end

      it "creates reaction" do
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "readinglist"
        }

        expect(Reaction.last.reactable_id).to eq(article.id)
      end

      it "creates rating vote" do
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "readinglist"
        }

        rating_vote = RatingVote.last
        expect(rating_vote.context).to eq("readinglist_reaction")
        expect(rating_vote.rating).to be(8.0)
      end

      it "does not attempt to create a rating vote when the user's experience level is unset" do
        user.setting.update_column(:experience_level, nil)
        allow(RatingVote).to receive(:create)

        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "readinglist"
        }

        expect(RatingVote).not_to have_received(:create)
      end

      it "has success http status" do
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "readinglist"
        }
        expect(response).to be_successful
      end
    end

    context "when attempting to create thumbsup as regular user" do
      before do
        sign_in user
      end

      it "does not permit the action" do
        expect do
          post "/reactions", params: {
            reactable_id: article.id,
            reactable_type: "Article",
            category: "thumbsup"
          }
        end.to raise_error(Pundit::NotAuthorizedError)
        expect(Reaction.where(category: "thumbsup").count).to eq(0)
      end
    end

    context "when creating thumbsup" do
      before do
        user.add_role(:trusted)
        sign_in user
      end

      it "clears thumbsdown comments but not like" do
        create(:reaction, reactable: article, user: user, points: 1, category: "like")
        create(:reaction, reactable: article, user: user, points: 1, category: "thumbsdown")
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "thumbsup"
        }
        expect(Reaction.where(category: "thumbsup").count).to eq(1)
        expect(Reaction.where(category: "thumbsdown").count).to eq(0)
        expect(Reaction.where(category: "like").count).to eq(1)
      end

      it "has success http status" do
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "thumbsup"
        }
        expect(response).to be_successful
      end
    end

    context "when creating thumbsdown" do
      before do
        user.add_role(:trusted)
        sign_in user
      end

      it "clears thumbsup comments but not vomit or like" do
        create(:reaction, reactable: article, user: user, points: 1, category: "vomit")
        create(:reaction, reactable: article, user: user, points: 1, category: "thumbsup")
        create(:reaction, reactable: article, user: user, points: 1, category: "like")
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "thumbsdown"
        }
        expect(Reaction.where(category: "thumbsdown").size).to be 1
        expect(Reaction.where(category: "thumbsup").size).to be 0
        expect(Reaction.where(category: "like").size).to be 1
        expect(Reaction.where(category: "vomit").size).to be 1
      end

      it "has success http status" do
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "thumbsdown"
        }
        expect(response).to be_successful
      end
    end

    context "when vomiting on a user" do
      before do
        sign_in trusted_user
      end

      it "creates reaction" do
        expect do
          post "/reactions", params: user_params
        end.to change(Reaction, :count).by(1)
      end

      it "destroys existing reaction" do
        post "/reactions", params: user_params
        expect do
          post "/reactions", params: user_params
        end.to change(Reaction, :count).by(-1)
      end

      it "has success http status" do
        post "/reactions", params: user_params
        expect(response).to be_successful
      end
    end

    context "when signed in as admin" do
      let(:admin) { create(:user, :admin) }

      before do
        sign_in admin
      end

      it "automatically confirms vomits on users" do
        post "/reactions", params: user_params

        reaction = Reaction.find_by(reactable_id: user.id)
        expect(reaction.category).to eq("vomit")
        expect(reaction.status).to eq("confirmed")
      end

      it "automatically confirms vomits on articles" do
        post "/reactions", params: article_params.merge(category: "vomit")

        reaction = Reaction.find_by(reactable_id: article.id)
        expect(reaction.category).to eq("vomit")
        expect(reaction.status).to eq("confirmed")
      end

      it "does not automatically confirm positive reactions" do
        post "/reactions", params: article_params

        reaction = Reaction.find_by(reactable_id: article.id)
        expect(reaction.category).to eq("like")
        expect(reaction.status).to eq("valid")
      end

      it "has success http status" do
        post "/reactions", params: article_params
        expect(response).to be_successful
      end
    end

    context "when signed out" do
      it "returns an unauthorized error" do
        expect { post "/reactions", params: article_params }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
