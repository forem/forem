class RemoveUnusedColumnsFromFeedbackMessages < ActiveRecord::Migration[5.1]
  def change
    remove_column :feedback_messages, :last_reviewed_at
    remove_column :feedback_messages, :offender_email_sent?
    remove_column :feedback_messages, :reporter_email_sent?
    remove_column :feedback_messages, :victim_email_sent?
    rename_column :feedback_messages, :victim_id, :affected_id
  end
end
