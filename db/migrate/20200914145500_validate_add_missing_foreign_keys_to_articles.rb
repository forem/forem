class ValidateAddMissingForeignKeysToArticles < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :articles, :collections
  end
end
