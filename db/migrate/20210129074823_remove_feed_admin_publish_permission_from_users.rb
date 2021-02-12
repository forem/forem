class RemoveFeedAdminPublishPermissionFromUsers < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :users, :feed_admin_publish_permission
    end
  end
end
