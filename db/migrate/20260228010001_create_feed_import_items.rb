class CreateFeedImportItems < ActiveRecord::Migration[7.0]
  def change
    create_table :feed_import_items do |t|
      t.references :feed_import_log, null: false, foreign_key: { on_delete: :cascade }
      t.references :article, null: true, foreign_key: { on_delete: :nullify }
      t.string :feed_item_url, null: false
      t.string :feed_item_title
      t.integer :status, null: false, default: 0
      t.string :error_message

      t.timestamps
    end
  end
end
