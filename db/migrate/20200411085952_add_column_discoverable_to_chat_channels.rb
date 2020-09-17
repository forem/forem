class AddColumnDiscoverableToChatChannels < ActiveRecord::Migration[5.2]
  def change
    add_column :chat_channels, :discoverable, :boolean, :default => false
  end
end
