class ChangeBroadcastAndGithubIssuePksToBigint < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      change_column :broadcasts, :id, :bigint
      change_column :github_issues, :id, :bigint
    }
  end

  def down
    safety_assured {
      change_column :broadcasts, :id, :int
      change_column :github_issues, :id, :int
    }
  end
end
