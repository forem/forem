class CreateTables < (Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[5.0])
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              :null => true, :default => ""
      t.string :encrypted_password, :null => true, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      t.string :username
      t.integer :profile_id
      t.boolean :active

      ## Invitable
      t.string   :invitation_token, :limit => 60
      t.datetime :invitation_created_at
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
      t.integer  :invitation_limit
      t.integer  :invited_by_id
      t.string   :invited_by_type
      t.integer :invitations_count, :default => 0

      t.timestamps :null => false
    end
    add_index :users, :invitation_token, :unique => true

    create_table :admins do |t|
      ## Database authenticatable
      t.string :email,              :null => true, :default => ""
      t.string :encrypted_password, :null => true, :default => ""

      t.integer :invitations_count, :default => 0
    end
  end
end
