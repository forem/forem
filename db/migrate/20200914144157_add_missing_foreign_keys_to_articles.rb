class AddMissingForeignKeysToArticles < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :articles, :collections, on_delete: :nullify, validate: false
  end
end
