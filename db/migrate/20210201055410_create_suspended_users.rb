class CreateSuspendedUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :suspended_users, id: false do |t|
      t.string :username_hash, primary_key: true

      t.timestamps
    end
  end
end
