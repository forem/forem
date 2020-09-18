class ChangePodcastPKstoBigint < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      change_column :podcasts, :id, :bigint
      change_column :podcast_episodes, :id, :bigint
      change_column :podcast_episodes, :podcast_id, :bigint
    }
  end

  def down
    safety_assured {
      change_column :podcasts, :id, :int
      change_column :podcast_episodes, :id, :int
      change_column :podcast_episodes, :podcast_id, :int
    }
  end
end
