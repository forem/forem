class AddUserIdMailerIndexToAhoyMessages < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :ahoy_messages, %i[user_id mailer], algorithm: :concurrently
  end
end
