class AddIndexToSearchDocumentsContent < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :pg_search_documents,
              %[to_tsvector('simple', coalesce("pg_search_documents"."content"::text, ''))],
              using: :gin,
              name: "index_pg_search_documents_on_content",
              algorithm: :concurrently
  end
end
