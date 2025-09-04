class AddSurveyExclusionToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :display_ads, :exclude_survey_completions, :boolean, default: false, null: false
    add_column :display_ads, :exclude_survey_ids, :integer, default: [], array: true, null: false
    
    # Add index for efficient filtering by survey exclusion
    add_index :display_ads, :exclude_survey_completions, name: 'idx_display_ads_survey_completions', algorithm: :concurrently
    add_index :display_ads, :exclude_survey_ids, using: :gin, name: 'idx_display_ads_survey_ids', algorithm: :concurrently
  end
end
