class ChangeSmallTableRelatedIdsToBigints < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.buffer_updates")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE buffer_updates
          ALTER COLUMN article_id TYPE bigint,
          ALTER COLUMN approver_user_id TYPE bigint,
          ALTER COLUMN composer_user_id TYPE bigint,
          ALTER COLUMN tag_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.collections")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE collections
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN organization_id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.github_repos")
    safety_assured { change_column :github_repos, :user_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.html_variants")
    safety_assured { change_column :html_variants, :user_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.mentions")
    safety_assured { change_column :mentions, :mentionable_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.organizations")
    safety_assured { change_column :organizations, :id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.tweets")
    safety_assured { change_column :tweets, :user_id, :bigint }
  end

  def down
        ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.buffer_updates")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE buffer_updates
          ALTER COLUMN article_id TYPE int,
          ALTER COLUMN approver_user_id TYPE int,
          ALTER COLUMN composer_user_id TYPE int,
          ALTER COLUMN tag_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.collections")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE collections
          ALTER COLUMN id TYPE int,
          ALTER COLUMN organization_id TYPE int,
          ALTER COLUMN user_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.github_repos")
    safety_assured { change_column :github_repos, :user_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.html_variants")
    safety_assured { change_column :html_variants, :user_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.mentions")
    safety_assured { change_column :mentions, :mentionable_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.organizations")
    safety_assured { change_column :organizations, :id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.tweets")
    safety_assured { change_column :tweets, :user_id, :int }
  end
end
