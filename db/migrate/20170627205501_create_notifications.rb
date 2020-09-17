class CreateNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :notifications do |t|
      t.integer :notifiable_id
      t.integer :user_id
      t.string :notifiable_type
      t.text :body_html
      t.string :action

      t.timestamps null: false
    end
  end
end
