class AddFeaturedNumberToArticles < ActiveRecord::Migration
  def change
    add_column :sponsors, :url, :string
    add_column :sponsorships, :url, :string
    add_column :articles, :featured_number, :integer
    add_column :podcast_episodes, :featured_number, :integer
    add_column :podcast_episodes, :featured, :boolean, default:true
    add_column :kis, :featured_number, :integer
  end
end
