class AddAdditionalSponsorOptionsToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :sponsorship_level, :string
    add_column :organizations, :sponsorship_expires_at, :datetime
    add_column :tags, :sponsor_organization_id, :integer
  end
end
