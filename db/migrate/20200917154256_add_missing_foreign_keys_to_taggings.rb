class AddMissingForeignKeysToTaggings < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :taggings, :tags, on_delete: :cascade, validate: false
  end
end
