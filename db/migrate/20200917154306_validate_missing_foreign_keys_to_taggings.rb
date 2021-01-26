class ValidateMissingForeignKeysToTaggings < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :taggings, :tags
  end
end
