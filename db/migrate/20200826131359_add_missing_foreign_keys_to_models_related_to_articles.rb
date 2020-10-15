class AddMissingForeignKeysToModelsRelatedToArticles < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :buffer_updates, :articles, on_delete: :cascade, validate: false
    add_foreign_key :rating_votes, :articles, on_delete: :cascade, validate: false
  end
end
