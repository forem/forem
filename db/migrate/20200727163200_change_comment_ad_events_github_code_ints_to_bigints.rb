class ChangeCommentAdEventsGithubCodeIntsToBigints < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.display_ad_events")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE display_ad_events
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN display_ad_id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.comments")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE comments
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint,
          ALTER COLUMN commentable_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.github_repos")
    safety_assured { change_column :github_repos, :github_id_code, :bigint }
  end

  def down
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.display_ad_events")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE display_ad_events
          ALTER COLUMN id TYPE int,
          ALTER COLUMN display_ad_id TYPE int,
          ALTER COLUMN user_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.comments")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE comments
          ALTER COLUMN id TYPE int,
          ALTER COLUMN user_id TYPE int,
          ALTER COLUMN commentable_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.github_repos")
    safety_assured { change_column :github_repos, :github_id_code, :int }
  end
end
