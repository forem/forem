class AddSponsorshipOrderToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :sponsorship_featured_number, :integer, default: 0
  end
end
