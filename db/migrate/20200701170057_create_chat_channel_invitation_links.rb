class CreateChatChannelInvitationLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :chat_channel_invitation_links do |t|
      t.belongs_to :chat_channel
      t.string :url
      t.datetime :expiry_time
      t.integer :use_count
      t.string :slug
      t.string :status
      t.timestamps
    end
  end
end
