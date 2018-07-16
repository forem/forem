class AddDescriptionToChatChannels < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_channels, :description, :string
  end
end
