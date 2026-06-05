class AddIndexesToConceptsAndMetrics < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Ensure pgvector is updated
    safety_assured { execute "ALTER EXTENSION vector UPDATE;" }

    # Concepts indexes
    add_index :concepts, :slug, unique: true, algorithm: :concurrently
    add_index :concepts, :parent_id, algorithm: :concurrently
    add_index :concepts, :anchor_embedding, using: :hnsw, opclass: :vector_cosine_ops, algorithm: :concurrently

    # ConceptMemberships indexes
    add_index :concept_memberships, :concept_id, algorithm: :concurrently
    add_index :concept_memberships, [:record_type, :record_id], algorithm: :concurrently
    add_index :concept_memberships, [:concept_id, :record_type, :record_id], unique: true, name: "index_concept_memberships_uniqueness", algorithm: :concurrently

    # ConceptDailyMetrics indexes
    add_index :concept_daily_metrics, :concept_id, algorithm: :concurrently
    add_index :concept_daily_metrics, :date, algorithm: :concurrently
    add_index :concept_daily_metrics, [:concept_id, :date], unique: true, name: "index_concept_daily_metrics_uniqueness", algorithm: :concurrently

    # Comments index
    add_index :comments, :semantic_embedding, using: :hnsw, opclass: :vector_cosine_ops, algorithm: :concurrently
  end

  def down
    remove_index :comments, :semantic_embedding, algorithm: :concurrently
    remove_index :concept_daily_metrics, name: "index_concept_daily_metrics_uniqueness", algorithm: :concurrently
    remove_index :concept_daily_metrics, :date, algorithm: :concurrently
    remove_index :concept_daily_metrics, :concept_id, algorithm: :concurrently
    remove_index :concept_memberships, name: "index_concept_memberships_uniqueness", algorithm: :concurrently
    remove_index :concept_memberships, column: [:record_type, :record_id], algorithm: :concurrently
    remove_index :concept_memberships, :concept_id, algorithm: :concurrently
    remove_index :concepts, :anchor_embedding, algorithm: :concurrently
    remove_index :concepts, :parent_id, algorithm: :concurrently
    remove_index :concepts, :slug, algorithm: :concurrently
  end
end
