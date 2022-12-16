class AddQuickShareToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :quick_share, :boolean, default:false
  end
end
