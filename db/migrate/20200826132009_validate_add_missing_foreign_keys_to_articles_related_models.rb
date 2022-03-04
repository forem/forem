class ValidateAddMissingForeignKeysToArticlesRelatedModels < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :buffer_updates, :articles
    validate_foreign_key :rating_votes, :articles
  end
end
