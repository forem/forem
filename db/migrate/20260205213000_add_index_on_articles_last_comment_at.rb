class AddIndexOnArticlesLastCommentAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :articles,
              [:subforem_id, :last_comment_at],
              order: { last_comment_at: :desc },
              where: "published IS TRUE",
              name: "index_articles_on_subforem_id_and_last_comment_at",
              algorithm: :concurrently
  end
end
