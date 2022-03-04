class AddCrosspostedAtToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :crossposted_at, :datetime
  end
end
