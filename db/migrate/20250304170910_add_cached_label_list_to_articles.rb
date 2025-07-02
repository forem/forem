class AddCachedLabelListToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :cached_label_list, :string, array: true, default: []
  end
end
