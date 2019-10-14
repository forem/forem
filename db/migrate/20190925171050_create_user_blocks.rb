class CreateUserBlocks < ActiveRecord::Migration[5.2]
  def change
    create_table :user_blocks do |t|
      t.bigint :blocked_id, null: false
      t.bigint :blocker_id, null: false
      t.string :config, null: false, default: "default"

      t.timestamps null: false
    end
  end
end
