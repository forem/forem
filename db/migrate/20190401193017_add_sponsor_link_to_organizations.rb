class AddSponsorLinkToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :sponsorship_url, :string
    add_column :organizations, :is_gold_sponsor, :boolean, default: false
    add_column :organizations, :sponsorship_tagline, :string
    add_column :organizations, :sponsorship_blurb_html, :text
  end
end
