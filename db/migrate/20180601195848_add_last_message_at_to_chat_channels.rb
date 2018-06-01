class AddLastMessageAtToChatChannels < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_channels, :last_message_at, :datetime, default: "2017-01-01 05:00:00"
    add_column :chat_channel_memberships, :last_opened_at, :datetime, default: "2017-01-01 05:00:00"
  end
end
