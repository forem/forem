class ValidateAddMissingForeignKeysToAhoyModels < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :ahoy_events, :ahoy_visits
    validate_foreign_key :ahoy_events, :users
    validate_foreign_key :ahoy_messages, :users
    validate_foreign_key :ahoy_visits, :users
  end
end
