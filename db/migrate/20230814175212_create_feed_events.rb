class CreateFeedEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :feed_events do |t|
      t.integer :article_position
      t.integer :category, null: false
      t.string :context_type, null: false

      t.references :article, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }

      t.timestamps
    end
  end
end
