class AddCachedTagListToDisplayAds < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :cached_tag_list, :string
  end
end
