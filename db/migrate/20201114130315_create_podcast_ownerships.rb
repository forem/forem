class CreatePodcastOwnerships < ActiveRecord::Migration[6.0]
  def change
    create_table :podcast_ownerships do |t|
      t.references :podcast, foreign_key: true, index: false, null: false
      t.references :user, foreign_key: true, index: false, null: false
      t.timestamps
    end
    add_index :podcast_ownerships, %i[podcast_id user_id], unique: true
  end
end
