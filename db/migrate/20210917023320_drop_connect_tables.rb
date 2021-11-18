class DropConnectTables < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      remove_foreign_key :chat_channel_memberships, :chat_channels
      remove_foreign_key :chat_channel_memberships, :users
      remove_foreign_key :tags, :chat_channels, column: :mod_chat_channel_id

      drop_table :messages
      drop_table :chat_channel_memberships
      drop_table :chat_channels
    end
  end

  def down
    raise ActivRecord::IrreversibleMigratione
  end
end
