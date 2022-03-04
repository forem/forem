class AddLastBufferedToArticles < ActiveRecord::Migration[5.0]
  def change
    add_column :articles, :last_buffered, :datetime
  end
end
