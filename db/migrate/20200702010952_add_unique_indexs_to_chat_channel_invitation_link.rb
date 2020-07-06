class AddUniqueIndexsToChatChannelInvitationLink < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :chat_channel_invitation_links, :slug, unique: true, algorithm: :concurrently
    add_index :chat_channel_invitation_links, :url, unique: true, algorithm: :concurrently
  end
end
