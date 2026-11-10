class AddSignInTokenIndexToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :users, :sign_in_token, where: "sign_in_token IS NOT NULL", algorithm: :concurrently, if_not_exists: true
  end
end
