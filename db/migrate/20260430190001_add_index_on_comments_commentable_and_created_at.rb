class AddIndexOnCommentsCommentableAndCreatedAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Speeds up date-bounded analytics queries that join on
  # (commentable_id, commentable_type) and then filter by created_at.
  def up
    safety_assured do
      db_user = connection.query_value("SELECT current_user")
      begin
        execute "ALTER ROLE \"#{db_user}\" SET statement_timeout = 0;"
        execute "SET statement_timeout = 0;"

        remove_index :comments, name: "index_comments_on_commentable_and_created_at", if_exists: true, algorithm: :concurrently

        add_index :comments,
                  %i[commentable_id commentable_type created_at],
                  name: "index_comments_on_commentable_and_created_at",
                  algorithm: :concurrently
      ensure
        execute "ALTER ROLE \"#{db_user}\" RESET statement_timeout;"
      end
    end
  end

  def down
    remove_index :comments, name: "index_comments_on_commentable_and_created_at", if_exists: true, algorithm: :concurrently
  end
end
