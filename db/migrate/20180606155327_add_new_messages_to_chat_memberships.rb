class AddNewMessagesToChatMemberships < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_channel_memberships, :has_unopened_messages, :boolean, default: false
  end
end
