class AddInvitationTokenToOrganizationMemberships < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_column :organization_memberships, :invitation_token, :string
    add_index :organization_memberships, :invitation_token, unique: true, algorithm: :concurrently
  end
end
