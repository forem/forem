class AddVideoToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :video, :string
    add_column :articles, :video_code, :string
    add_column :articles, :video_source_url, :string
    add_column :articles, :video_thumbnail_url, :string
    add_column :articles, :video_closed_caption_track_url, :string
  end
end
