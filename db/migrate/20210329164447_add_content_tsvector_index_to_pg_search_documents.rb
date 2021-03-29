class AddContentTsvectorIndexToPgSearchDocuments < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :pg_search_documents,
              "to_tsvector('simple'::regconfig, COALESCE((content)::text, ''::text))",
              using: :gin,
              algorithm: :concurrently,
              name: "index_pg_search_documents_on_username_as_tsvector"
  end
end
