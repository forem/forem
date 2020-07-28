class ChangeMentionsNotesPodcastsRolesRelatedIdsToBigints < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.mentions")
    safety_assured { change_column :mentions, :user_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.notes")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE notes
          ALTER COLUMN author_id TYPE bigint,
          ALTER COLUMN noteable_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.podcasts")
    safety_assured { change_column :podcasts, :creator_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.roles")
    safety_assured { change_column :roles, :resource_id, :bigint }
  end

  def down
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.mentions")
    safety_assured { change_column :mentions, :user_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.notes")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE notes
          ALTER COLUMN author_id TYPE int,
          ALTER COLUMN noteable_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.podcasts")
    safety_assured { change_column :podcasts, :creator_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.roles")
    safety_assured { change_column :roles, :resource_id, :int }
  end
end
