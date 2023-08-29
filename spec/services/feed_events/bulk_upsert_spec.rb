require "rails_helper"

RSpec.describe FeedEvents::BulkUpsert, type: :service do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }

  def feed_event(**attributes)
    build(:feed_event, **attributes).attributes
  end

  context "when there are no duplicates in the list or database" do
    let(:articles) { create_list(:article, 5) }
    let(:feed_events_data) do
      articles
        .map
        .with_index do |article, index|
          {
            article: article,
            user: user,
            article_position: index + 1,
            category: :impression,
            context_type: FeedEvent::CONTEXT_TYPE_HOME
          }
        end
    end

    it "inserts all the feed events" do
      expect { described_class.call(feed_events_data) }.to change(FeedEvent, :count).by(5)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to match_array(
        articles.map { |article| [article.id, user.id, "impression"] },
      )
    end
  end

  context "when there are duplicate events within the list" do
    let(:article) { create(:article) }
    let(:feed_events_data) do
      Array.new(5) do
        feed_event(article: article, user: user, category: :click)
      end
    end

    it "does not insert extra duplicate events" do
      expect { described_class.call(feed_events_data) }.to change(FeedEvent, :count).by(1)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, user.id, "click"],
      )
    end
  end

  context "when there are invalid events in the list" do
    let(:article) { create(:article) }
    let(:feed_events_data) do
      [
        feed_event(article: nil, user: user, category: :click),
        feed_event(article: article, user: user).merge(category: :not_a_real_category),
        feed_event(article: article, user: user, category: :impression),
        feed_event(article: article, user: nil, category: :impression),
        feed_event(article: article, user: second_user, category: :impression, context_type: "blahblahblah"),
        feed_event(article: article, user: second_user, category: :click, article_position: -2),
      ]
    end

    it "filters them out" do
      expect { described_class.call(feed_events_data, timebox: nil) }.to change(FeedEvent, :count).by(2)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, user.id, "impression"],
        [article.id, nil, "impression"],
      )
    end
  end

  context "when there is only one valid item in the list" do
    let(:article) { create(:article) }
    let(:feed_event_data) do
      [
        feed_event(article: article, user: user, category: :click, context_type: "foobar"),
        feed_event(article: article, user: second_user, category: :impression),
      ]
    end

    it "handles it appropriately" do
      expect { described_class.call(feed_event_data) }.to change(FeedEvent, :count).by(1)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, second_user.id, "impression"],
      )
    end
  end

  context "when there are no valid items in the list" do
    let(:feed_event_data) do
      [
        feed_event(article: nil, user: user, category: :click),
        feed_event(article: nil, user: second_user, category: :click),
      ]
    end

    it "does nothing and returns" do
      allow(FeedEvent).to receive(:where).and_call_original

      expect { described_class.call(feed_event_data) }.not_to change(FeedEvent, :count)

      expect(FeedEvent).not_to have_received(:where)
    end
  end

  context "when there are already existing events with the same article, user and category" do
    let(:article) { create(:article) }
    let(:second_article) { create(:article) }
    let(:feed_events_data) do
      [
        feed_event(article: article, user: user, category: :impression),
        feed_event(article: article, user: user, category: :click),
        feed_event(article: article, user: second_user, category: :impression),
        feed_event(article: second_article, user: user, category: :impression),
      ]
    end

    before do
      create(:feed_event, article: article, user: user, category: :impression)
      create(:feed_event, article: article, user: second_user, category: :impression)
    end

    it "ignores them if no timebox is provided" do
      expect { described_class.call(feed_events_data, timebox: nil) }.to change(FeedEvent, :count).by(4)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, user.id, "impression"],
        [article.id, second_user.id, "impression"],
        [article.id, user.id, "impression"],
        [article.id, user.id, "click"],
        [article.id, second_user.id, "impression"],
        [second_article.id, user.id, "impression"],
      )
    end

    it "does not create new events if the existing matching events were created within the provided timebox" do
      Timecop.travel(7.minutes.from_now) do
        expect { described_class.call(feed_events_data, timebox: 10.minutes) }.to change(FeedEvent, :count).by(2)
        expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
          [article.id, user.id, "impression"],
          [article.id, second_user.id, "impression"],
          [article.id, user.id, "click"],
          [second_article.id, user.id, "impression"],
        )
      end
    end

    it "creates new events if the existing matching events were created outside the provided timebox" do
      Timecop.travel(12.minutes.from_now) do
        expect { described_class.call(feed_events_data, timebox: 10.minutes) }.to change(FeedEvent, :count).by(4)
        expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
          [article.id, user.id, "impression"],
          [article.id, second_user.id, "impression"],
          [article.id, user.id, "impression"],
          [article.id, user.id, "click"],
          [article.id, second_user.id, "impression"],
          [second_article.id, user.id, "impression"],
        )
      end
    end
  end
end
