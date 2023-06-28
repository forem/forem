class RemoveFeaturedNumberFromArticles < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :articles, :featured_number
    end
  end
end
