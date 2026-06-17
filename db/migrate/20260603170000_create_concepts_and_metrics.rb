class CreateConceptsAndMetrics < ActiveRecord::Migration[7.0]
  def up
    create_table :concepts do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.vector :anchor_embedding, limit: 768, null: false
      t.bigint :parent_id

      t.timestamps
    end

    create_table :concept_memberships do |t|
      t.bigint :concept_id, null: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.float :distance, null: false

      t.timestamps
    end

    safety_assured do
      add_foreign_key :concept_memberships, :concepts, on_delete: :cascade
    end

    create_table :concept_daily_metrics do |t|
      t.bigint :concept_id, null: false
      t.date :date, null: false
      t.integer :articles_count, default: 0, null: false
      t.integer :comments_count, default: 0, null: false
      t.integer :page_views, default: 0, null: false
      t.integer :reactions_count, default: 0, null: false
      t.float :popularity_score, default: 0.0, null: false

      t.timestamps
    end

    safety_assured do
      add_foreign_key :concept_daily_metrics, :concepts, on_delete: :cascade
    end

    add_column :comments, :semantic_embedding, :vector, limit: 768
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Rollback is data-destructive: dropped concept and comment embeddings cannot be restored."
  end
end
