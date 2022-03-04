class AddMissingForeignKeysNotificationsSubsPageViewsUsersRoles < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :notification_subscriptions, :users, on_delete: :cascade
    add_foreign_key :page_views, :articles, on_delete: :cascade
    add_foreign_key :users_roles, :users, on_delete: :cascade
  end
end
