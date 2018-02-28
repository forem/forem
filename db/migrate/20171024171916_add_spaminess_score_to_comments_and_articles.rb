class AddSpaminessScoreToCommentsAndArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :comments, :spaminess_rating, :integer, default: 0
    add_column :articles, :spaminess_rating, :integer, default: 0
  end
end
