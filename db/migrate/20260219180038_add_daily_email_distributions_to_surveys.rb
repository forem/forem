class AddDailyEmailDistributionsToSurveys < ActiveRecord::Migration[7.0]
  def change
    add_column :surveys, :daily_email_distributions, :integer, default: 0
  end
end
