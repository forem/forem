class AddAltUrlToSponsors < ActiveRecord::Migration
  def change
    add_column :sponsors, :alt_url, :string
  end
end
