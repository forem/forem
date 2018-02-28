class AddUrlToAdvertisments < ActiveRecord::Migration
  def change
    add_column :advertisements, :url, :text
  end
end
