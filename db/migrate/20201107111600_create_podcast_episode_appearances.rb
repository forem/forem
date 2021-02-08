class CreatePodcastEpisodeAppearances < ActiveRecord::Migration[6.0]
  def change
    create_table :podcast_episode_appearances do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :podcast_episode, null: false, foreign_key: true, index: false
      t.string :role, null: false, default: "guest"
      t.boolean :approved, null: false, default: false
      t.boolean :featured_on_user_profile, null: false, default: false
      t.timestamps
    end
    add_index :podcast_episode_appearances,
              %i[podcast_episode_id user_id],
              unique: true,
              name: "index_pod_episode_appearances_on_podcast_episode_id_and_user_id"
  end
end
