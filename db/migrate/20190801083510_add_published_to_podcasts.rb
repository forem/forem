class AddPublishedToPodcasts < ActiveRecord::Migration[5.2]
  class Podcast < ApplicationRecord; end

  def change
    add_column :podcasts, :published, :boolean, default: false

    Podcast.update_all(published: true)
  end
end
