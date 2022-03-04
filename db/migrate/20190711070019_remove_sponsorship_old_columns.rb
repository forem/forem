class RemoveSponsorshipOldColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :organizations, :is_gold_sponsor, :boolean, default: false
    remove_column :organizations, :sponsorship_blurb_html, :text
    remove_column :organizations, :sponsorship_expires_at, :datetime
    remove_column :organizations, :sponsorship_featured_number, :integer, default: 0
    remove_column :organizations, :sponsorship_instructions, :text, default: ""
    remove_column :organizations, :sponsorship_instructions_updated_at, :datetime
    remove_column :organizations, :sponsorship_level, :string
    remove_column :organizations, :sponsorship_status, :string, default: "none"
    remove_column :organizations, :sponsorship_tagline, :string
    remove_column :organizations, :sponsorship_url, :string

    remove_column :tags, :sponsor_organization_id, :integer
    remove_column :tags, :sponsorship_status, :string, default: "none"
  end
end
