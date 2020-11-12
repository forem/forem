class CreatePodcastAppearances < ActiveRecord::Migration[6.0]
  def change
    create_table :podcast_appearances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :podcast_episode, null: false, foreign_key: true
      t.string :role, null: false, default: "guest"
      t.boolean :approved, null: false, default: false
      t.boolean :featured_on_user_profile, null: false, default: false
      t.timestamps
    end
    add_index :podcast_appearances, %i[podcast_episode_id user_id], unique: true
  end
end
