class AddFeaturedToPodcasts < ActiveRecord::Migration[6.1]
  def change
    add_column :podcasts, :featured, :boolean, default: false
  end
end
