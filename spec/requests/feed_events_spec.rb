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
        expect { post "/feed_events", params: { feed_event: event_params } }.to change(FeedEvent, :count).by(1)

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
        expect { post "/feed_events", params: { feed_event: params } }.to change(FeedEvent, :count).by(1)

        expect(response).to be_successful
        expect(article.feed_events.first.category).to eq("impression")
      end

      it "fails silently if passed invalid params" do
        params = event_params.merge(context_type: "not a real context type")
        expect { post "/feed_events", params: { feed_event: params } }.not_to change(FeedEvent, :count)
        expect(response).to be_successful
      end
    end

    context "when user is not signed in" do
      it "silently does not create an event" do
        expect { post "/feed_events", params: { feed_event: event_params } }.not_to change(FeedEvent, :count)
        expect(response).to be_successful
      end
    end
  end
end
