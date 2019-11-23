class AddDeviseToUsers < ActiveRecord::Migration[4.2]
  def self.up
    change_table(:users) do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at


      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps null: false
    end

    # add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    # raise ActiveRecord::IrreversibleMigration
    # remove_index :users, :reset_password_token
    # remove_index :users, :email
    # remove_column :users, :encrypted_password
    # remove_column :users, :reset_password_token
    # remove_column :users, :reset_password_sent_at
    # remove_column :users, :email
    # remove_column :users, :remember_created_at
    # remove_column :users, :sign_in_count
    # remove_column :users, :current_sign_in_at
    # remove_column :users, :last_sign_in_at
    # remove_column :users, :current_sign_in_ip
    # remove_column :users, :last_sign_in_ip



  end
end
