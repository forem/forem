class AddIndexToAhoyMessagesTo < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :ahoy_messages, :to, algorithm: :concurrently
  end
end
