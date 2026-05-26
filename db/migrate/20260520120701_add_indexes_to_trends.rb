class AddIndexesToTrends < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_index :trends, :slug, unique: true, algorithm: :concurrently
    add_index :trends, :centroid_embedding, using: :hnsw, opclass: :vector_cosine_ops, algorithm: :concurrently
    add_index :trend_memberships, [:trend_id, :article_id], unique: true, name: "index_trend_memberships_uniqueness", algorithm: :concurrently
    add_index :trend_memberships, :article_id, algorithm: :concurrently
  end

  def down
    remove_index :trend_memberships, :article_id, algorithm: :concurrently
    remove_index :trend_memberships, name: "index_trend_memberships_uniqueness", algorithm: :concurrently
    remove_index :trends, :centroid_embedding, algorithm: :concurrently
    remove_index :trends, :slug, algorithm: :concurrently
  end
end
