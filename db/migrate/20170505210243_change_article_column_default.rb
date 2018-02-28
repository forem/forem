class ChangeArticleColumnDefault < ActiveRecord::Migration
  def change
    change_column_default(:articles, :show_comments, true)
  end
end
