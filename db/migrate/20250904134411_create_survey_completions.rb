class CreateSurveyCompletions < ActiveRecord::Migration[7.0]
  def change
    create_table :survey_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :survey, null: false, foreign_key: true
      t.datetime :completed_at, null: false

      t.timestamps
    end

    # Add unique index to prevent duplicate completions
    add_index :survey_completions, [:user_id, :survey_id], unique: true, name: 'idx_survey_completions_user_survey'
    
    # Add index for efficient lookups by user
    add_index :survey_completions, :user_id, name: 'idx_survey_completions_user'
    
    # Add index for efficient lookups by survey
    add_index :survey_completions, :survey_id, name: 'idx_survey_completions_survey'
  end
end
