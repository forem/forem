class AddNthPublished < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :nth_published_by_author, :integer, default: 0
  end
end
