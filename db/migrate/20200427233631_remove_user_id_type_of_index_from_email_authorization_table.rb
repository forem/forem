class RemoveUserIdTypeOfIndexFromEmailAuthorizationTable < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :email_authorizations, column: [:user_id, :type_of], algorithm: :concurrently
  end
end
