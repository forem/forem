class AddColumnsToFeedbackMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :feedback_messages, :created_at, :datetime
    add_column :feedback_messages, :updated_at, :datetime
    add_column :feedback_messages, :last_reviewed_at, :datetime
    add_column :feedback_messages, :status, :string, default: "Open"
    add_column :feedback_messages, :victim_email_sent?, :boolean, default: false
    add_column :feedback_messages, :reporter_email_sent?, :boolean, default: false
    add_column :feedback_messages, :offender_email_sent?, :boolean, default: false
    add_column :feedback_messages, :slug, :string
    add_column :feedback_messages, :reported_url, :string
    rename_column :feedback_messages, :user_id, :reporter_id
    rename_column :feedback_messages, :category_selection, :category
    add_column :feedback_messages, :reviewer_id, :integer
    add_column :feedback_messages, :offender_id, :integer
    add_column :feedback_messages, :victim_id, :integer
  end
end
