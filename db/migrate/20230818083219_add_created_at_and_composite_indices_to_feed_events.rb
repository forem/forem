class AddCreatedAtAndCompositeIndicesToFeedEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :feed_events, :created_at, algorithm: :concurrently

    add_index :feed_events,
              %i[article_id user_id category],
              name: "index_feed_events_on_article_user_and_category",
              algorithm: :concurrently
  end
end
