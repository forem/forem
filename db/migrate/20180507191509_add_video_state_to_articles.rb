class AddVideoStateToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :video_state, :string
  end
end
