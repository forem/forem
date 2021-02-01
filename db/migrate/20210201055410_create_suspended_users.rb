class CreateSuspendedUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :suspended_users do |t|
      t.string :username_hash, null: false

      t.timestamps
    end

    add_index :suspended_users, :username_hash, unique: true
  end
end
