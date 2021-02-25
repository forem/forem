class AddMissingForeignKeysToAhoyMessages < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :ahoy_messages, :feedback_messages, on_delete: :nullify, validate: false
  end
end
