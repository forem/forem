class AddVectorIndexesForFeed < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Dynamically check if the current Postgres environment supports HNSW indexes (pgvector >= 0.5.0)
    # If not, gracefully fall back to IVFFlat indexes for older environments.
    index_type = select_value("SELECT 1 FROM pg_am WHERE amname = 'hnsw'") ? :hnsw : :ivfflat

    add_index :user_activities, :interest_embedding, using: index_type, opclass: :vector_cosine_ops, algorithm: :concurrently
    add_index :articles, :semantic_embedding, using: index_type, opclass: :vector_cosine_ops, algorithm: :concurrently
  end

  def down
    remove_index :articles, :semantic_embedding, algorithm: :concurrently
    remove_index :user_activities, :interest_embedding, algorithm: :concurrently
  end
end
