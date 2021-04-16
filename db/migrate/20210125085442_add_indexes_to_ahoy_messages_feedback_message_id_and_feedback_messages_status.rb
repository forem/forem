class AddIndexesToAhoyMessagesFeedbackMessageIdAndFeedbackMessagesStatus < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :ahoy_messages, :feedback_message_id, algorithm: :concurrently
    add_index :feedback_messages, :status, algorithm: :concurrently
  end
end
