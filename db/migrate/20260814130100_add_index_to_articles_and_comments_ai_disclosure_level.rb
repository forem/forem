class AddIndexToArticlesAndCommentsAiDisclosureLevel < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      db_user = connection.query_value("SELECT current_user")
      begin
        execute "ALTER ROLE \"#{db_user}\" SET statement_timeout = 0;"
        execute "SET statement_timeout = 0;"

        # Drop in case a previous deploy timed out and left an invalid index
        remove_index :articles, name: "index_articles_on_ai_disclosure_level", if_exists: true, algorithm: :concurrently
        add_index :articles, :ai_disclosure_level, algorithm: :concurrently

        remove_index :comments, name: "index_comments_on_ai_disclosure_level", if_exists: true, algorithm: :concurrently
        add_index :comments, :ai_disclosure_level, algorithm: :concurrently
      ensure
        execute "ALTER ROLE \"#{db_user}\" RESET statement_timeout;"
      end
    end
  end

  def down
    safety_assured do
      remove_index :articles, name: "index_articles_on_ai_disclosure_level", if_exists: true, algorithm: :concurrently
      remove_index :comments, name: "index_comments_on_ai_disclosure_level", if_exists: true, algorithm: :concurrently
    end
  end
end
