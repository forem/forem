class AddRedditInfoToLinks < ActiveRecord::Migration
  def change
    add_column :links, :reddit_score, :integer, default: 0
  end
end
