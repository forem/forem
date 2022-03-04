class CreateUserBlocks < ActiveRecord::Migration[5.2]
  def change
    create_table :user_blocks do |t|
      t.bigint :blocked_id, null: false
      t.bigint :blocker_id, null: false
      t.string :config, null: false, default: "default"

      t.timestamps null: false
    end

    add_index :user_blocks, %i[blocked_id blocker_id], unique: true
    add_foreign_key :user_blocks, :users, column: :blocker_id
    add_foreign_key :user_blocks, :users, column: :blocked_id
  end
end
