class AddAdditionalSponsorOptionsToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :sponsorship_level, :string
    add_column :organizations, :sponsorship_expires_at, :datetime
    add_column :organizations, :sponsorship_status, :string, default: "none"
    add_column :organizations, :sponsorship_instructions, :text, default: ""
    add_column :organizations, :sponsorship_instructions_updated_at, :datetime
    add_column :tags, :sponsor_organization_id, :integer
    add_column :tags, :sponsorship_status, :string, default: "none"
  end
end
