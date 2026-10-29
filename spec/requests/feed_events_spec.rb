require "rails_helper"

RSpec.describe "FeedEvents" do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:event_params) do
    {
      article_id: article.id,
      article_position: 4,
      category: :click,
      context_type: FeedEvent::CONTEXT_TYPE_HOME
    }
  end

  around do |example|
    previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store = previous_store
  end

  describe "POST /feed_events" do
    context "when user is signed in" do
      before do
        sign_in user
      end

      it "creates a feed click event" do
        expect { post "/feed_events", params: { feed_events: [event_params] } }.to change(FeedEvent, :count).by(1)

        expect(response).to be_successful
        expect(article.feed_events.first).to have_attributes(
          user_id: user.id,
          article_position: 4,
          category: "click",
          context_type: "home",
        )
      end

      it "creates a feed impression event" do
        params = event_params.merge(category: :impression)
        expect { post "/feed_events", params: { feed_events: [params] } }.to change(FeedEvent, :count).by(1)

        expect(response).to be_successful
        expect(article.feed_events.first.category).to eq("impression")
      end

      it "preserves the client event ID and acknowledges retries without inserting twice" do
        event = event_params.merge(event_id: SecureRandom.uuid)
        post "/feed_events", params: { feed_events: [event] }
        expect(response).to be_successful
        expect(article.feed_events.first.event_id).to eq(event[:event_id])
        Timecop.travel(6.minutes.from_now) do
          expect { post "/feed_events", params: { feed_events: [event] } }.not_to change(FeedEvent, :count)
        end
        expect(response).to be_successful
      end

      it "filters malformed event IDs and missing categories without rejecting valid events" do
        events = [event_params.merge(event_id: "invalid"), event_params.except(:category), event_params]
        expect { post "/feed_events", params: { feed_events: events } }.to change(FeedEvent, :count).by(1)
        expect(response).to be_successful
      end

      it "rejects a malformed UUID rather than casting it to a legacy event with no ID" do
        expect do
          post "/feed_events", params: { feed_events: [event_params.merge(event_id: "invalid")] }
        end.not_to change(FeedEvent, :count)
        expect(response).to be_successful
      end

      it "rejects oversized payloads before reserving receipts" do
        events = Array.new(21) { event_params.merge(event_id: SecureRandom.uuid) }
        expect { post "/feed_events", params: { feed_events: events } }.not_to change(FeedEventReceipt, :count)
        expect(response).to have_http_status(:payload_too_large)
      end

      it "rejects malformed batch shapes" do
        post "/feed_events", params: { feed_events: ["invalid"] }
        expect(response).to have_http_status(:bad_request)
      end

      it "acknowledges without ingesting while the kill switch is enabled" do
        allow(FeatureFlag).to receive(:enabled?).with(:disable_browser_feed_events).and_return(true)
        expect { post "/feed_events", params: { feed_events: [event_params] } }.not_to change(FeedEvent, :count)
        expect(response).to be_successful
      end

      it "bounds per-user admission and supplies Retry-After" do
        Timecop.freeze do
          allow(FeedEvents::BulkUpsert).to receive(:call)
          120.times { post "/feed_events", params: { feed_events: [event_params] } }
          post "/feed_events", params: { feed_events: [event_params] }
          expect(response).to have_http_status(:too_many_requests)
          expect(response.headers["Retry-After"]).to eq("60")
          expect(FeedEvents::BulkUpsert).to have_received(:call).exactly(120).times
          Timecop.travel(61.seconds.from_now) do
            post "/feed_events", params: { feed_events: [event_params] }
            expect(response).to be_successful
          end
        end
      end

      it "creates multiple events in a batch" do
        second_article = create(:article)
        events = [
          {
            article_id: article.id,
            article_position: 20,
            category: :impression,
            context_type: FeedEvent::CONTEXT_TYPE_HOME
          },
          {
            article_id: article.id,
            article_position: 20,
            category: :click,
            context_type: FeedEvent::CONTEXT_TYPE_HOME
          },
          {
            article_id: second_article.id,
            article_position: 7,
            category: :impression,
            context_type: FeedEvent::CONTEXT_TYPE_TAG
          },
          {
            article_id: second_article.id,
            article_position: 7,
            category: :click,
            context_type: FeedEvent::CONTEXT_TYPE_TAG
          },
        ]
        expect { post "/feed_events", params: { feed_events: events } }.to change(FeedEvent, :count).by(4)
        expect(response).to be_successful
      end
    end

    context "when user is not signed in" do
      it "silently does not create an event" do
        expect { post "/feed_events", params: { feed_events: [event_params] } }.not_to change(FeedEvent, :count)
        expect(response).to be_successful
      end
    end

    context "when a token is provided" do
      let(:token)          { JWT.encode({ "user_id" => user.id }, Rails.application.secret_key_base, "HS256") }
      let(:headers)        { { "Authorization" => "Bearer #{token}" } }

      it "creates a feed click event when passed as header" do
        expect do
          post "/feed_events", params: { feed_events: [event_params] }, headers: headers
        end.to change(FeedEvent, :count).by(1)

        expect(response).to be_successful
        expect(article.feed_events.first).to have_attributes(
          user_id: user.id,
          article_id: article.id,
          article_position: 4,
          category: "click",
          context_type: "home",
        )
      end

      it "creates a feed impression event when passed as param" do
        expect do
          post "/feed_events", params: { feed_events: [event_params], jwt: token }
        end.to change(FeedEvent, :count).by(1)

        expect(response).to be_successful
        expect(article.feed_events.first).to have_attributes(
          user_id: user.id,
          article_id: article.id,
          article_position: 4,
          category: "click",
          context_type: "home",
        )
      end
    end
  end
end
