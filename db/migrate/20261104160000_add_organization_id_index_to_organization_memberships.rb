class AddOrganizationIdIndexToOrganizationMemberships < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :organization_memberships, %i[organization_id type_of_user],
              name: "index_org_memberships_on_org_id_and_type_of_user",
              algorithm: :concurrently
  end
end
