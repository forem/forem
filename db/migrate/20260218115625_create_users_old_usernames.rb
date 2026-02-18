class CreateUsersOldUsernames < ActiveRecord::Migration[7.0]
  def change
    create_table :users_old_usernames do |t|
      t.references :user, null: false, foreign_key: true
      t.string :username, null: false

      t.timestamps
    end

    add_index :users_old_usernames, :username, unique: true
  end
end
