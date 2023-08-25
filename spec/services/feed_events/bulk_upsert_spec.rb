require "rails_helper"

RSpec.describe FeedEvents::BulkUpsert, type: :service do
  let(:first_user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:articles) { create_list(:article, 5) }
  let(:feed_events_data) do
    base_attributes = {
      user_id: first_user.id,
      category: :impression,
      context_type: FeedEvent::CONTEXT_TYPE_HOME
    }
    articles
      .map
      .with_index { |article, index| base_attributes.merge(article_id: article.id, article_position: index + 1) }
      .push(base_attributes.merge(article_id: articles.first.id, article_position: 1, category: :click))
  end

  it "inserts feed events and increases points count when there are no duplicates" do
    expect { described_class.call(feed_events_data) }.to change(FeedEvent, :count).by(6)

    expect(FeedEvent.sum(:counts_for)).to eq(6)
  end
end
