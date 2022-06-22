class RemoveSpaminessRatingFromArticles < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :articles, :spaminess_rating, :integer }
  end
end
