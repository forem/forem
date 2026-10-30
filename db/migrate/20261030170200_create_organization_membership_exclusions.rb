class CreateOrganizationMembershipExclusions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    create_table :organization_membership_exclusions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index(
      :organization_membership_exclusions, %i[organization_id user_id],
      unique: true, algorithm: :concurrently, name: "index_org_membership_exclusions_on_org_and_user"
    )
  end
end
