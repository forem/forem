class AddIndexToArticlesFavoritedByUserId < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :articles, name: "index_articles_on_favorited_by_user_id", if_exists: true
      add_index :articles, :favorited_by_user_id, if_not_exists: true
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :articles, name: "index_articles_on_favorited_by_user_id", if_exists: true
    end
  end
end
