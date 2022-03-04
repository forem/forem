class AddTrigramIndexToCommentsAncestry < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :comments, :ancestry,
      # There is already a btree index on this column, so we need to specify a different name
      name: 'index_comments_on_ancestry_trgm',
      # Using trigram operations requires a GIN index
      using: :gin,
      # Indexing for LIKE operations requires trigram operations
      opclass: :gin_trgm_ops,
      algorithm: :concurrently
  end
end
