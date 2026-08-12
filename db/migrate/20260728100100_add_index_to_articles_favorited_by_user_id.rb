class AddIndexToArticlesFavoritedByUserId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      db_user = connection.query_value("SELECT current_user")
      begin
        execute "ALTER ROLE \"#{db_user}\" SET statement_timeout = 0;"
        execute "SET statement_timeout = 0;"

        remove_index :articles, name: "index_articles_on_favorited_by_user_id", if_exists: true,
                                algorithm: :concurrently

        add_index :articles, :favorited_by_user_id, algorithm: :concurrently
      ensure
        execute "ALTER ROLE \"#{db_user}\" RESET statement_timeout;"
      end
    end
  end

  def down
    safety_assured do
      remove_index :articles, name: "index_articles_on_favorited_by_user_id", if_exists: true, algorithm: :concurrently
    end
  end
end
