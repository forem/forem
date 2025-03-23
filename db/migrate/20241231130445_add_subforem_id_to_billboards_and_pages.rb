class AddSubforemIdToBillboardsAndPages < ActiveRecord::Migration[7.0]
  def change
    add_column :navigation_links, :subforem_id, :bigint
    add_column :display_ads, :include_subforem_ids, :integer, array: true, default: []
    add_column :pages, :subforem_id, :bigint
  end
end
