class DropMentorRelationships < ActiveRecord::Migration[5.2]
  def change
    drop_table :mentor_relationships do |t|
      t.integer :mentor_id, null: false
      t.integer :mentee_id, null: false
      t.boolean :active, default: true
      t.timestamps
      t.index :mentee_id
      t.index :mentor_id
      t.index %i[mentee_id mentor_id], unique: true
    end
  end
end
