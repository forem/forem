class CreateChatChannels < ActiveRecord::Migration[5.1]
  def change
    create_table :chat_channels do |t|
      t.string :channel_type, null: false

      t.timestamps
    end
  end
end
