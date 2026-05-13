class AddVectorIndexesForFeed < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_index :user_activities, :interest_embedding, using: :hnsw, opclass: :vector_cosine_ops, algorithm: :concurrently
    add_index :articles, :semantic_embedding, using: :hnsw, opclass: :vector_cosine_ops, algorithm: :concurrently
  end

  def down
    remove_index :articles, :semantic_embedding, algorithm: :concurrently
    remove_index :user_activities, :interest_embedding, algorithm: :concurrently
  end
end
