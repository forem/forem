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
  end
end
