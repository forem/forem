class CreatePodcasts < ActiveRecord::Migration
  def change
    create_table :podcasts do |t|
      t.string :title
      t.text   :description
      t.string :feed_url
      t.string :itunes_url
      t.string :image
      t.string :slug
      t.timestamps null: false
    end
  end
end
