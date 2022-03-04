class AddIdsForOtherArticlesToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :ids_for_suggested_articles, :string, default: "[]"
  end
end
