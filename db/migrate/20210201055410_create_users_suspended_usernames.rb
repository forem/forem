class CreateUsersSuspendedUsernames < ActiveRecord::Migration[6.0]
  def change
    create_table :users_suspended_usernames, id: false do |t|
      t.string :username_hash, primary_key: true

      t.timestamps
    end
  end
end
