class AddInvitationTokenToOrganizationMemberships < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      # 1. Kill the timeout for this specific migration
      execute "SET statement_timeout = 0;"

      # 2. Add the column (checking if it exists from the first failed run)
      add_column :organization_memberships, 
                 :invitation_token, 
                 :string, 
                 if_not_exists: true

      # 3. Add the index concurrently (checking if it exists)
      add_index :organization_memberships, 
                :invitation_token, 
                unique: true, 
                algorithm: :concurrently, 
                if_not_exists: true
    end
  end
end