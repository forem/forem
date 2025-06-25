class AddCompositeIndexToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    safety_assured do
      add_index :articles,
                [:published, :canonical_url],
                name: 'index_articles_on_published_and_canonical_url',
                algorithm: :concurrently
    end
  end
end
