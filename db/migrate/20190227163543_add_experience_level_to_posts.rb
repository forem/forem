class AddExperienceLevelToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :experience_level_rating, :float, default: 5.0
    add_column :articles, :experience_level_rating_distribution, :float, default: 5.0
    add_column :articles, :last_experience_level_rating_at, :datetime
    add_column :articles, :rating_votes_count, :integer, null: false, default: 0
    add_column :users, :rating_votes_count, :integer, null: false, default: 0
  end
end
