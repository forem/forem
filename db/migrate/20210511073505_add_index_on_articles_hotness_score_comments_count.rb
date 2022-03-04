class AddIndexOnArticlesHotnessScoreCommentsCount < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    columns = %i[hotness_score comments_count]

    add_index :articles, columns, algorithm: :concurrently unless index_exists?(:articles, columns)
  end

  def down
    columns = %i[hotness_score comments_count]

    remove_index :articles, column: columns, algorithm: :concurrently if index_exists?(:articles, columns)
  end
end
