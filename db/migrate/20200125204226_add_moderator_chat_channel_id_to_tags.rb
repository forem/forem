class AddModeratorChatChannelIdToTags < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :mod_chat_channel_id, :integer
  end
end
