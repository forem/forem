class RemoveTwitterCountsFromUser < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :users, :twitter_following_count, :integer
      remove_column :users, :twitter_followers_count, :integer
    end
  end
end
