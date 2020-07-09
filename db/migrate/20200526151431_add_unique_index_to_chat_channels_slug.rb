class AddUniqueIndexToChatChannelsSlug < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :chat_channels, :slug, unique: true, algorithm: :concurrently
  end
end
