class CreateTrends < ActiveRecord::Migration[7.0]
  def change
    create_table :trends do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.text :key_questions, array: true, default: []
      t.vector :centroid_embedding, limit: 768, null: false
      t.float :score, default: 0.0, null: false
      t.integer :articles_count, default: 0, null: false
      t.datetime :first_observed_at, null: false
      t.datetime :last_observed_at, null: false

      t.timestamps
    end

    create_table :trend_memberships do |t|
      t.belongs_to :trend, null: false, foreign_key: true, index: false
      t.belongs_to :article, null: false, foreign_key: true, index: false
      t.float :distance, null: false

      t.timestamps
    end
  end
end
