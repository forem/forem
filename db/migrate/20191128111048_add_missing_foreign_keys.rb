class AddMissingForeignKeys < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :api_secrets, :users, on_delete: :cascade
    add_foreign_key :classified_listings, :users, on_delete: :cascade
    add_foreign_key :identities, :users, on_delete: :cascade
    add_foreign_key :notification_subscriptions, :users, on_delete: :cascade
    add_foreign_key :page_views, :articles, on_delete: :nullify
    add_foreign_key :tag_adjustments, :users, on_delete: :cascade
    add_foreign_key :tag_adjustments, :articles, on_delete: :cascade
    add_foreign_key :tag_adjustments, :tags, on_delete: :cascade
    add_foreign_key :users_roles, :users, on_delete: :cascade
  end
end
