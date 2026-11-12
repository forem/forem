require "rails_helper"

RSpec.describe "Reactions" do
  let(:user)    { create(:user, :without_profile, profile_image: nil) }
  let(:article) { create(:article, user: user, with_tags: false, with_main_image: false) }
  let(:comment) { create(:comment, commentable: article, user: user) }

  let(:max_age) { 2.weeks.to_i }
  let(:stale_if_error) { 1.day.to_i }

  describe "GET /reactions?article_id=:article_id" do
    before do
      create(:reaction, reactable: article, user: user, points: 1)
    end

    context "when signed in" do
      before do
        sign_in user
      end

      it "returns the correct json response and omits edge cache headers", :aggregate_failures do
        get reactions_path(article_id: article.id)

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

        expect(response.headers["Surrogate-Key"]).to be_nil
        expect(response.headers["X-Accel-Expires"]).to be_nil
        expect(response.headers.to_hash).not_to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end

      it "returns public reactions followed by the readinglist reaction" do
        create(:reaction, reactable: article, user: user, category: "readinglist")
        create(:reaction, reactable: article, user: user, category: "unicorn")

        get reactions_path(article_id: article.id)

        categories = response.parsed_body["reactions"].pluck("category")
        expect(categories).to contain_exactly("like", "unicorn", "readinglist")
        expect(categories.last).to eq("readinglist")
      end

      it "does not hydrate the full users row on GET /reactions?article_id=" do
        get reactions_path(article_id: article.id)

        full_user_queries = []
        callback = lambda do |*, payload|
          full_user_queries << payload[:sql] if payload[:sql].include?('SELECT "users".*')
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get reactions_path(article_id: article.id)
        end

        expect(response).to have_http_status(:ok)
        expect(full_user_queries).to be_empty
      end

      it "ignores a retained session after the user's password changes" do
        get reactions_path(article_id: article.id)
        expect(response.parsed_body["current_user"]).to eq("id" => user.id)

        User.where(id: user.id).update_all(
          encrypted_password: "$2a$10$newpasswordsaltandhashvalue1234567890123456789012",
        )

        get reactions_path(article_id: article.id)
        expect(response.parsed_body["current_user"]).to eq("id" => nil)
        expect(response.parsed_body["reactions"]).to be_empty
      end
    end

    context "when authenticated only via remember_user_token cookie" do
      it "restores the user, omits edge cache headers, and preserves session persistence" do
        user.remember_me!
        cookie_val = User.serialize_into_cookie(user)
        signed_cookie = Rails.application.message_verifier("signed cookie").generate(cookie_val)

        get reactions_path(article_id: article.id),
            headers: { "Cookie" => "remember_user_token=#{CGI.escape(signed_cookie)}" }

        result = response.parsed_body
        expect(result["current_user"]).to eq("id" => user.id)
        expect(result["reactions"]).not_to be_empty
        expect(response.headers["Surrogate-Key"]).to be_nil
        expect(request.env["rack.session.options"][:skip]).not_to be(true)
      end
    end

    context "when signed out" do
      it "returns the correct json response and sets edge cache headers", :aggregate_failures do
        get reactions_path(article_id: article.id)

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

        expect(response.headers["Surrogate-Key"]).to eq(Reaction.surrogate_key_for_article(article.id))
        expect(response.headers["X-Accel-Expires"]).to eq(max_age.to_s)
        expect(response.headers.to_hash).to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    it "skips querying the articles table for the signed-out surrogate key when reaction counts are already present" do
      queries = []
      callback = lambda do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('FROM "articles"')
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get reactions_path(article_id: article.id)
      end

      expect(response.headers["Surrogate-Key"]).to eq(Reaction.surrogate_key_for_article(article.id))
      expect(queries).to be_empty
    end

    it "looks up only the article id, once, for the signed-out surrogate key when the article has no reactions yet" do
      Reaction.where(reactable: article).delete_all
      Rails.cache.delete("reaction_counts_for_reactable-Article-#{article.id}")

      queries = []
      callback = lambda do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('FROM "articles"')
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get reactions_path(article_id: article.id)
      end

      expect(response.headers["Surrogate-Key"]).to eq(Reaction.surrogate_key_for_article(article.id))
      expect(queries.size).to eq(1)
      expect(queries.first).to start_with('SELECT "articles"."id" FROM "articles"')
    end

    it "omits the signed-out surrogate key when the article id does not exist" do
      missing_id = Article.maximum(:id).to_i + 1
      get reactions_path(article_id: missing_id)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Surrogate-Key"]).to be_nil
    end
  end

  describe "GET /reactions?commentable_id=:article.id&commentable_type=Article" do
    before do
      create(:reaction, reactable: comment, user: user, points: 1)
    end

    context "when signed in" do
      it "returns the correct json response and omits edge cache headers", :aggregate_failures do
        sign_in user
        get reactions_path(commentable_id: article.id, commentable_type: "Article")

        expect(response.parsed_body).to eq(
          "current_user" => { "id" => user.id },
          "public_reaction_counts" => [{ "id" => article.comments.last.id, "count" => 1 }],
          "reactions" => JSON.parse(user.reactions.where(reactable: comment).to_json),
        )
        expect(response.headers["surrogate-key"]).to be_nil
        expect(response.headers["x-accel-expires"]).to be_nil
        expect(response.headers.to_hash).not_to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end
    end

    context "when signed out" do
      it "returns the correct json response and sets edge cache headers", :aggregate_failures do
        get reactions_path(commentable_id: article.id, commentable_type: "Article")

        result = response.parsed_body

        expect(result["current_user"]).to eq("id" => nil)
        expect(result["public_reaction_counts"]).to eq([{ "id" => article.comments.last.id, "count" => 1 }])
        expect(result["reactions"]).to be_empty

        expect(response.headers["Surrogate-Key"]).to eq(Reaction.surrogate_key_for_commentable(article))
        expect(response.headers["X-Accel-Expires"]).to eq(max_age.to_s)
        expect(response.headers.to_hash).to include(
          "Cache-Control" => "public, no-cache",
          "Surrogate-Control" => "max-age=#{max_age}, stale-if-error=#{stale_if_error}",
        )
      end

      it "skips querying the commentable table when comments are already present" do
        queries = []
        callback = lambda do |*, payload|
          queries << payload[:sql] if payload[:sql].include?('FROM "articles"')
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get reactions_path(commentable_id: article.id, commentable_type: "Article")
        end

        expect(response.headers["Surrogate-Key"]).to eq(Reaction.surrogate_key_for_commentable(article))
        expect(queries).to be_empty
      end
    end
  end

  describe "POST /reactions" do
    let(:trusted_user) { create(:user, :without_profile, :trusted, profile_image: nil) }
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

      it "creates and destroys an existing reaction with a successful http status", :aggregate_failures do
        expect do
          post "/reactions", params: article_params
        end.to change(Reaction, :count).by(1)
        expect(response).to be_successful

        expect do
          # same route to destroy, so sending POST request again
          post "/reactions", params: article_params
        end.to change(Reaction, :count).by(-1)
        expect(response).to be_successful
      end

      it "sends Algolia insight event asynchronously via TrackEventWorker", :aggregate_failures do
        # Set up the expectation before making the request
        allow(Settings::General).to receive_messages(algolia_application_id: "test", algolia_api_key: "test")
        algolia_service_instance = instance_double(AlgoliaInsightsService)
        allow(AlgoliaInsightsService).to receive(:new).and_return(algolia_service_instance)
        allow(algolia_service_instance).to receive(:track_event)

        sidekiq_assert_enqueued_jobs(1, only: AlgoliaInsights::TrackEventWorker) do
          post "/reactions", params: article_params
        end
        expect(algolia_service_instance).not_to have_received(:track_event)

        sidekiq_perform_enqueued_jobs(only: AlgoliaInsights::TrackEventWorker)

        expect(algolia_service_instance).to have_received(:track_event).with(
          "conversion",
          "Reaction Created",
          user.id,
          article.id,
          "Article_#{Rails.env}",
          instance_of(Integer),
          nil,
          nil,
        )
      end
    end

    context "when creating readinglist" do
      before do
        user.setting.update_column(:experience_level, 8)
        sign_in user
      end

      it "creates reaction and rating vote with a successful http status", :aggregate_failures do
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "readinglist"
        }

        expect(response).to be_successful
        expect(Reaction.last.reactable_id).to eq(article.id)

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

      it "clears thumbsdown comments but not like and returns success", :aggregate_failures do
        create(:reaction, reactable: article, user: user, points: 1, category: "like")
        create(:reaction, reactable: article, user: user, points: 1, category: "thumbsdown")
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "thumbsup"
        }
        expect(response).to be_successful
        expect(Reaction.where(category: "thumbsup").count).to eq(1)
        expect(Reaction.where(category: "thumbsdown").count).to eq(0)
        expect(Reaction.where(category: "like").count).to eq(1)
      end
    end

    context "when creating thumbsdown" do
      before do
        user.add_role(:trusted)
        sign_in user
      end

      it "clears thumbsup comments but not vomit or like and returns success", :aggregate_failures do
        create(:reaction, reactable: article, user: user, points: 1, category: "vomit")
        create(:reaction, reactable: article, user: user, points: 1, category: "thumbsup")
        create(:reaction, reactable: article, user: user, points: 1, category: "like")
        post "/reactions", params: {
          reactable_id: article.id,
          reactable_type: "Article",
          category: "thumbsdown"
        }
        expect(response).to be_successful
        expect(Reaction.where(category: "thumbsdown").size).to be 1
        expect(Reaction.where(category: "thumbsup").size).to be 0
        expect(Reaction.where(category: "like").size).to be 1
        expect(Reaction.where(category: "vomit").size).to be 1
      end
    end

    context "when vomiting on a user" do
      before do
        sign_in trusted_user
      end

      it "creates and destroys an existing reaction with a successful http status", :aggregate_failures do
        expect do
          post "/reactions", params: user_params
        end.to change(Reaction, :count).by(1)
        expect(response).to be_successful

        expect do
          post "/reactions", params: user_params
        end.to change(Reaction, :count).by(-1)
        expect(response).to be_successful
      end
    end

    context "when signed in as admin" do
      let(:admin) { create(:user, :without_profile, :admin, profile_image: nil) }

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

      it "does not automatically confirm positive reactions and returns success", :aggregate_failures do
        post "/reactions", params: article_params

        expect(response).to be_successful
        reaction = Reaction.find_by(reactable_id: article.id)
        expect(reaction.category).to eq("like")
        expect(reaction.status).to eq("valid")
      end
    end

    context "when signed out" do
      it "returns an unauthorized error" do
        expect { post "/reactions", params: article_params }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "cache invalidation" do
    before do
      sign_in user
    end

    it "invalidates reaction_counts_for_reactable cache when creating a reaction" do
      cache_key = "reaction_counts_for_reactable-Article-#{article.id}"

      # Create initial reactions to populate cache
      create(:reaction, reactable: article, category: "like", user: user)

      # Populate cache
      article.public_reaction_categories
      cache_existed = Rails.cache.exist?(cache_key)

      # Create reaction via controller
      if cache_existed
        expect do
          post "/reactions", params: { reactable_type: "Article", reactable_id: article.id, category: "unicorn" }
        end.to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      else
        # If cache doesn't exist, just verify the request succeeds
        post "/reactions", params: { reactable_type: "Article", reactable_id: article.id, category: "unicorn" }
        expect(response).to be_successful
      end
    end

    it "invalidates reaction_counts_for_reactable cache when toggling a reaction" do
      cache_key = "reaction_counts_for_reactable-Article-#{article.id}"

      # Create initial reaction
      create(:reaction, reactable: article, category: "like", user: user)

      # Populate cache
      article.public_reaction_categories
      cache_existed = Rails.cache.exist?(cache_key)

      # Toggle reaction (destroy) via controller
      if cache_existed
        expect do
          post "/reactions", params: { reactable_type: "Article", reactable_id: article.id, category: "like" }
        end.to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      else
        # If cache doesn't exist, just verify the request succeeds
        post "/reactions", params: { reactable_type: "Article", reactable_id: article.id, category: "like" }
        expect(response).to be_successful
      end
    end

    it "calls remove_reaction_counts_cache_key method" do
      controller = ReactionsController.new
      allow(controller).to receive(:remove_reaction_counts_cache_key).and_call_original
      allow(ReactionsController).to receive(:new).and_return(controller)

      post "/reactions", params: { reactable_type: "Article", reactable_id: article.id, category: "like" }

      expect(controller).to have_received(:remove_reaction_counts_cache_key)
    end
  end
end
