class AddModerationIndexesToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change

    safety_assured do
      execute "SET statement_timeout = 0;"

      # Composite index for the main moderation query pattern
      # This covers: published, score range, published_at ordering
      add_index :articles,
                [:published, :score, :published_at],
                name: 'index_articles_on_published_score_published_at_for_moderation',
                algorithm: :concurrently

      # Index for nth_published_by_author filtering
      add_index :articles,
                [:published, :nth_published_by_author],
                name: 'index_articles_on_published_nth_published_by_author',
                algorithm: :concurrently

      # Composite index for subforem + published + score queries
      add_index :articles,
                [:subforem_id, :published, :score, :published_at],
                name: 'index_articles_on_subforem_published_score_published_at',
                algorithm: :concurrently

    end
  end
end
