class UpdateFeedbackMessagesTable < ActiveRecord::Migration[5.1]
  def change
    remove_column :feedback_messages, :last_reviewed_at, :datetime
    remove_column :feedback_messages, :offender_email_sent?, :boolean
    remove_column :feedback_messages, :reporter_email_sent?, :boolean
    remove_column :feedback_messages, :victim_email_sent?, :boolean
    rename_column :feedback_messages, :victim_id, :affected_id
  end
end
