class AddFeedbackMessageIdToEmail < ActiveRecord::Migration[5.1]
  def change
    add_column :ahoy_messages, :feedback_message_id, :integer
  end
end
