class CreateRecommendedArticlesLists < ActiveRecord::Migration[7.0]
  def change
    create_table :recommended_articles_lists do |t|
      t.string     :name
      t.integer    :article_ids, array: true, default: []
      t.integer    :placement_area, default: 0
      t.datetime   :expires_at
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
    #add_column :display_ads, :exclude_article_ids, :integer, array: true, default: []
