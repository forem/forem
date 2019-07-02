class AddReachableToPodcasts < ActiveRecord::Migration[5.2]
  def change
    add_column :podcasts, :reachable, :boolean, default: true
  end
end
