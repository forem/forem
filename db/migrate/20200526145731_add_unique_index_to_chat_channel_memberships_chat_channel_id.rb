class AddUniqueIndexToChatChannelMembershipsChatChannelId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :chat_channel_memberships, %i[chat_channel_id user_id], unique: true, algorithm: :concurrently
  end
end
