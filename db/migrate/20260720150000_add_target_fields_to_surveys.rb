class AddTargetFieldsToSurveys < ActiveRecord::Migration[8.0]
  def change
    add_column :surveys, :target_response_count, :integer, default: 0, null: false
    add_column :surveys, :target_completion_date, :datetime
    add_column :surveys, :sending_started_at, :datetime
    add_column :surveys, :emails_sent_count, :integer, default: 0, null: false
  end
end
