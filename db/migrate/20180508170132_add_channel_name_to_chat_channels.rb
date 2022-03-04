class AddChannelNameToChatChannels < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_channels, :channel_name, :string
  end
end
