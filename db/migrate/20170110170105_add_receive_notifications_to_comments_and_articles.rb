class AddReceiveNotificationsToCommentsAndArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :receive_notifications, :boolean, default: true
    add_column :comments, :receive_notifications, :boolean, default: true
  end
end
