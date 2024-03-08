class RemoveTagsModChatChannelId < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :tags, :mod_chat_channel_id
    end
  end
end
