class CreateMentorRelationships < ActiveRecord::Migration[5.1]
  def change
    create_table :mentor_relationships do |t|
      t.integer :mentor_id, null: false
      t.integer :mentee_id, null: false
      t.timestamps
    end
    add_index :mentor_relationships, :mentee_id
    add_index :mentor_relationships, :mentor_id
    add_index :mentor_relationships, %i[mentee_id mentor_id], unique: true
  end
end
