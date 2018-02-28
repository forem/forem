class AddIdsForOtherArticlesToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :ids_for_suggested_articles, :string, default: "[]"
  end
end
