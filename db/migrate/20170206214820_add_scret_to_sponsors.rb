class AddScretToSponsors < ActiveRecord::Migration
  def change
    add_column :sponsors, :url_secret, :string
  end
end
