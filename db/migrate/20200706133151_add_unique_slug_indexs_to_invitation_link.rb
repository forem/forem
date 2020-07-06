class AddUniqueSlugIndexsToInvitationLink < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :invitation_links, :slug, unique: true, algorithm: :concurrently
  end
end
