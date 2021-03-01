class FinalBigintMigration < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.api_secrets")
    safety_assured { change_column :api_secrets, :user_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.badge_achievements")
    safety_assured { change_column :badge_achievements, :rewarder_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.broadcasts")
    safety_assured { change_column :broadcasts, :broadcastable_id, :bigint }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.display_ads")
    safety_assured { change_column :display_ads, :organization_id, :bigint }

    puts "migrating feedback_messages PKs to bigints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.feedback_messages")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE feedback_messages
          ALTER COLUMN affected_id TYPE bigint,
          ALTER COLUMN offender_id TYPE bigint,
          ALTER COLUMN reporter_id TYPE bigint
      SQL
    )

    puts "migrating html_variant_successes PKs to bigints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.html_variant_successes")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE html_variant_successes
          ALTER COLUMN article_id TYPE bigint,
          ALTER COLUMN html_variant_id TYPE bigint
      SQL
    )

    puts "migrating html_variant_trials PKs to bigints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.html_variant_trials")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE html_variant_trials
          ALTER COLUMN article_id TYPE bigint,
          ALTER COLUMN html_variant_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.users_roles")
    safety_assured { change_column :users_roles, :user_id, :bigint }
  end

  def down
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.api_secrets")
    safety_assured { change_column :api_secrets, :user_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.badge_achievements")
    safety_assured { change_column :badge_achievements, :rewarder_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.broadcasts")
    safety_assured { change_column :broadcasts, :broadcastable_id, :int }

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.display_ads")
    safety_assured { change_column :display_ads, :organization_id, :int }

    puts "migrating feedback_messages PKs to ints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.feedback_messages")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE feedback_messages
          ALTER COLUMN affected_id TYPE int,
          ALTER COLUMN offender_id TYPE int,
          ALTER COLUMN reporter_id TYPE int
      SQL
    )

    puts "migrating html_variant_successes PKs to ints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.html_variant_successes")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE html_variant_successes
          ALTER COLUMN article_id TYPE int,
          ALTER COLUMN html_variant_id TYPE int
      SQL
    )

    puts "migrating html_variant_trials PKs to ints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.html_variant_trials")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE html_variant_trials
          ALTER COLUMN article_id TYPE int,
          ALTER COLUMN html_variant_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.users_roles")
    safety_assured { change_column :users_roles, :user_id, :int }
  end
end
