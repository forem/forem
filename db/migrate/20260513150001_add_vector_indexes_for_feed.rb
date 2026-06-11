class AddVectorIndexesForFeed < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Ensure the pgvector extension is updated to the latest available version on the system (needs to be >= 0.5.0 for hnsw)
    safety_assured { execute "ALTER EXTENSION vector UPDATE;" }


    # Use a single explicit pgvector access method so migrations and schema dumps are reproducible
    # across environments. This matches the checked-in schema definition.
    add_index :user_activities, :interest_embedding, using: :hnsw, opclass: :vector_cosine_ops, algorithm: :concurrently
    add_index :articles, :semantic_embedding, using: :hnsw, opclass: :vector_cosine_ops, algorithm: :concurrently
  end

  def down
    remove_index :articles, :semantic_embedding, algorithm: :concurrently
    remove_index :user_activities, :interest_embedding, algorithm: :concurrently
  end
end
