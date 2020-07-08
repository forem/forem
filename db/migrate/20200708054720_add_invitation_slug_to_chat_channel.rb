class AddInvitationSlugToChatChannel < ActiveRecord::Migration[6.0]
  def change
    add_column :chat_channels, :invitation_slug, :string
  end
end
