class CreatePodcastEpisodes < ActiveRecord::Migration[4.2]
  def change
    create_table :podcast_episodes do |t|
      t.integer :podcast_id
      t.string :title
      t.string :subtitle
      t.text   :summary
      t.string :media_url
      t.string :website_url
      t.string :itunes_url
      t.string :image
      t.integer  :duration_in_seconds
      t.datetime :published_at
      t.string :slug
      t.string :guid
      t.timestamps null: false
    end
  end
end
