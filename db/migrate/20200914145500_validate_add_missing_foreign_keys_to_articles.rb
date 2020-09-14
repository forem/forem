class ValidateAddMissingForeignKeysToArticles < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :articles, :collections
    validate_foreign_key :articles, :users, column: :second_user_id
    validate_foreign_key :articles, :users, column: :third_user_id
  end
end
