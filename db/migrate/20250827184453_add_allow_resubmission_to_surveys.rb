class AddAllowResubmissionToSurveys < ActiveRecord::Migration[7.0]
  def change
    add_column :surveys, :allow_resubmission, :boolean, default: false, null: false
  end
end
