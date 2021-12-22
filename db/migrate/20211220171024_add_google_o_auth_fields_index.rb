class AddGoogleOAuthFieldsIndex < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :users, :google_username, algorithm: :concurrently
  end
end
