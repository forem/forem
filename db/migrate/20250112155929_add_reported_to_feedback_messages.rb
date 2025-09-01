class AddReportedToFeedbackMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :feedback_messages, :reported_type, :string
    add_column :feedback_messages, :reported_id, :bigint
  end
end
