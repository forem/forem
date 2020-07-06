class CreateInvitationLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :invitation_links do |t|
      t.belongs_to :chat_channel
      t.string :path
      t.datetime :expiry_at
      t.string :slug
      t.integer :status
      t.timestamps
    end
  end
end
