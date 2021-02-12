class CreatePgSearchDocuments < ActiveRecord::Migration[6.0]
  def up
    say_with_time("Creating table for pg_search multisearch") do
      create_table :pg_search_documents do |t|
        t.text :content

        # columns needed for multisearch sorting (homepage feed and search)
        t.integer :hotness_score, null: false, index: true
        t.boolean :published, null: false, index: true
        t.datetime :published_at, null: false, index: true
        t.integer :public_reactions_count, null: false, index: true

        t.belongs_to :searchable, polymorphic: true, index: true
        t.timestamps null: false
      end
    end
  end

  def down
    say_with_time("Dropping table for pg_search multisearch") do
      drop_table :pg_search_documents
    end
  end
end
