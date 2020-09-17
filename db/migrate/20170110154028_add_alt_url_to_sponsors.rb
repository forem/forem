class AddAltUrlToSponsors < ActiveRecord::Migration[4.2]
  def change
    add_column :sponsors, :alt_url, :string
  end
end
