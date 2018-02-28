class CreateReactions < ActiveRecord::Migration
  def change
    create_table :reactions do |t|
      t.integer :user_id
      t.integer  :reactable_id
      t.string  :reactable_type
      t.string  :category
      t.float   :points, default: 1.0
      t.timestamps null: false
    end
    add_index("reactions", "user_id")
  end
end
