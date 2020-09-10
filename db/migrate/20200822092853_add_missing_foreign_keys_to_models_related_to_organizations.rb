class AddMissingForeignKeysToModelsRelatedToOrganizations < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :articles, :organizations, on_delete: :nullify, validate: false
    add_foreign_key :collections, :organizations, on_delete: :nullify, validate: false
    add_foreign_key :credits, :organizations, on_delete: :restrict, validate: false
    add_foreign_key :display_ads, :organizations, on_delete: :cascade, validate: false
    add_foreign_key :classified_listings, :organizations, on_delete: :cascade, validate: false
    add_foreign_key :notifications, :organizations, on_delete: :cascade, validate: false
    add_foreign_key :organization_memberships, :organizations, on_delete: :cascade, validate: false
  end
end
