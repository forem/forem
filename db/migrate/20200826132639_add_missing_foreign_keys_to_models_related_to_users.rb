class AddMissingForeignKeysToModelsRelatedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :articles, :users, on_delete: :cascade, validate: false
    add_foreign_key :collections, :users, on_delete: :cascade, validate: false
    add_foreign_key :comments, :users, on_delete: :cascade, validate: false
    add_foreign_key :credits, :users, on_delete: :cascade, validate: false
    add_foreign_key :github_repos, :users, on_delete: :cascade, validate: false
    add_foreign_key :html_variants, :users, on_delete: :cascade, validate: false
    add_foreign_key :mentions, :users, on_delete: :cascade, validate: false
    add_foreign_key :notifications, :users, on_delete: :cascade, validate: false
    add_foreign_key :organization_memberships, :users, on_delete: :cascade, validate: false
    add_foreign_key :page_views, :users, on_delete: :nullify, validate: false
    add_foreign_key :rating_votes, :users, on_delete: :nullify, validate: false
    add_foreign_key :reactions, :users, on_delete: :cascade, validate: false
    add_foreign_key :tweets, :users, on_delete: :nullify, validate: false
  end
end
