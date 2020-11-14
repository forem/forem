class CreatePodcastOwnerships < ActiveRecord::Migration[6.0]
  def change
    create_table :podcast_ownerships do |t|
      t.references :podcast, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.timestamps
    end
  end
end
