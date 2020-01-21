class AddBanishedUsersTable < ActiveRecord::Migration[5.2]
  def change
    create_table :banished_users do |t|
      t.string :username
      t.index :username, unique: true
      t.references :banished_by, references: :user

      t.timestamps
    end
  end
end
