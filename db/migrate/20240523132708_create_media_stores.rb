class CreateMediaStores < ActiveRecord::Migration[7.0]
  def change
    create_table :media_stores do |t|
      t.string :original_url, null: false
      t.string :output_url, null: false
      t.integer :media_type, null: false, default: 0
      t.timestamps
    end
    # index on original_url
    add_index :media_stores, :original_url, unique: true
  end
end
