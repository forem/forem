class ValidateAddMissingForeignKeysToAhoyMessages < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :ahoy_messages, :feedback_messages
  end
end
