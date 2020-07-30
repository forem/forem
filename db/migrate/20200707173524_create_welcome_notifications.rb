class CreateWelcomeNotifications < ActiveRecord::Migration[6.0]
  def change
    create_table :welcome_notifications do |t|
      t.timestamps
    end
  end
end
