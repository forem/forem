class AddEventIdIndexToArticles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_articles_on_event_id_published_hotness_published_at".freeze

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :articles, name: INDEX_NAME, if_exists: true, algorithm: :concurrently
      add_index :articles,
                %i[event_id published hotness_score published_at],
                order: { hotness_score: :desc, published_at: :desc },
                where: "event_id IS NOT NULL",
                name: INDEX_NAME,
                algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :articles, name: INDEX_NAME, if_exists: true, algorithm: :concurrently
    end
  end
end
