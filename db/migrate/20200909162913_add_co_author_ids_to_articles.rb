class AddCoAuthorIdsToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :co_author_ids, :bigint
  end
end
