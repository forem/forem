class RemoveProMemberships < ActiveRecord::Migration[5.2]
  def up
    drop_table :pro_memberships
  end

  def down
    create_table :pro_memberships do |t|
      t.references :user, foreign_key: true
      t.string :status, default: "active"
      t.datetime :expires_at, null: false
      t.datetime :expiration_notification_at
      t.integer :expiration_notifications_count, null: false, default: 0
      t.boolean :auto_recharge, null: false, default: false

      t.timestamps
    end
    add_index :pro_memberships, :status
    add_index :pro_memberships, :expires_at
    add_index :pro_memberships, :auto_recharge
  end
end
