class AddRedditInfoToLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :links, :reddit_score, :integer, default: 0
  end
end
