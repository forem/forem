class AddMissingForeignKeysToAhoyModels < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :ahoy_events, :ahoy_visits, column: :visit_id, on_delete: :cascade, validate: false
    add_foreign_key :ahoy_events, :users, on_delete: :cascade, validate: false
    add_foreign_key :ahoy_messages, :users, on_delete: :cascade, validate: false
    add_foreign_key :ahoy_visits, :users, on_delete: :cascade, validate: false
  end
end
