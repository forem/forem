class AddHeadlineToWelcomeNotifications < ActiveRecord::Migration[6.0]
  def change
    add_column :welcome_notifications, :headline, :string
  end
end
