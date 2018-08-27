class AddEmailUnreadMessagesToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :email_connect_messages, :boolean, default:true
  end
end