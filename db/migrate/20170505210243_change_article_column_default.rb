class ChangeArticleColumnDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default(:articles, :show_comments, true)
  end
end
