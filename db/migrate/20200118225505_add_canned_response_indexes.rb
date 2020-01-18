class AddCannedResponseIndexes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :canned_responses, :user_id, algorithm: :concurrently
    add_index :canned_responses, :type_of, algorithm: :concurrently
  end
end
