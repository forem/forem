class CreateChatChannelMemberships < ActiveRecord::Migration[5.1]
  def change
    create_table :chat_channel_memberships do |t|
      t.references :chat_channel, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.timestamps
    end
    add_index :chat_channel_memberships, [:user_id, :chat_channel_id]
  end
end
