class AddAdminPublishPermissionToRss < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :feed_admin_publish_permission, :boolean, default: true
    add_column :users, :feed_mark_canonical, :boolean, default: false
  end
end
