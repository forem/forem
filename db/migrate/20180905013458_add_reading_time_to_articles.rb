class AddReadingTimeToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :reading_time, :integer, default: 0
  end
end
