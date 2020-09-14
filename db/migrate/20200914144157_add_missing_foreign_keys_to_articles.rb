class AddMissingForeignKeysToArticles < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :articles, :collections, on_delete: :nullify, validate: false
    add_foreign_key :articles, :users, column: :second_user_id, on_delete: :nullify, validate: false
    add_foreign_key :articles, :users, column: :third_user_id, on_delete: :nullify, validate: false
  end
end
