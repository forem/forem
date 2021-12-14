class AddSecretToSponsors < ActiveRecord::Migration[4.2]
  def change
    add_column :sponsors, :url_secret, :string
  end
end
