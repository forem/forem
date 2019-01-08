class AddFeaturedImpressionsAndFeaturedCtrToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :featured_impressions, :integer, default: 0
    add_column :articles, :featured_clickthrough_rate, :float, default: 0.0
  end
end
