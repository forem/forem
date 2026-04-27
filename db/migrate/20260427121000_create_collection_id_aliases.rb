class CreateCollectionIdAliases < ActiveRecord::Migration[7.0]
  def change
    create_table :collection_id_aliases do |t|
      t.bigint :legacy_collection_id, null: false
      t.references :collection, null: false, foreign_key: true, type: :bigint

      t.timestamps
    end

    add_index :collection_id_aliases, :legacy_collection_id, unique: true
  end
end