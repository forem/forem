class AddOriginallyPublishedAt < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :originally_published_at, :datetime
  end
end
