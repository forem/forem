class AddConstraintsToPodcastEpisodes < ActiveRecord::Migration[5.2]
  def up
    change_table :podcast_episodes do |t|
      t.change :title, :string, null: false
      t.change :slug, :string, null: false
      t.change :media_url, :string, null: false
      t.change :guid, :string, null: false
    end
  end

  def down
    change_table :podcast_episodes do |t|
      t.change :title, :string
      t.change :slug, :string
      t.change :media_url, :string
      t.change :guid, :string
    end
  end
end
