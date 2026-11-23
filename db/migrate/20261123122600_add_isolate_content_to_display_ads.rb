class AddIsolateContentToDisplayAds < ActiveRecord::Migration[8.0]
  def change
    add_column :display_ads, :isolate_content, :boolean, default: false, null: false
  end
end
