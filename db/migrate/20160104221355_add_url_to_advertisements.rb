class AddUrlToAdvertisements < ActiveRecord::Migration[4.2]
  def change
    add_column :advertisements, :url, :text
  end
end
