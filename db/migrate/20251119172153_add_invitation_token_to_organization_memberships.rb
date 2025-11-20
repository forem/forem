class AddInvitationTokenToOrganizationMemberships < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :organization_memberships, :invitation_token, :string, if_not_exists: true

    disable_statement_timeout do
      add_index :organization_memberships, :invitation_token, unique: true, algorithm: :concurrently, if_not_exists: true
    end
  end
end