class LargeTablePrimaryKeysToBigints < ActiveRecord::Migration[6.0]
  def up
    puts "migrating ahoy_message PKs to bigints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.ahoy_messages")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE ahoy_messages
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint,
          ALTER COLUMN feedback_message_id TYPE bigint
      SQL
    )

    puts "migrating article PKs to bigints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.articles")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE articles
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint,
          ALTER COLUMN second_user_id TYPE bigint,
          ALTER COLUMN third_user_id TYPE bigint,
          ALTER COLUMN organization_id TYPE bigint,
          ALTER COLUMN collection_id TYPE bigint
      SQL
    )

    puts "migrating notification PKs to bigints"
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.notifications")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE notifications
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN notifiable_id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint
      SQL
    )
  end

  def down
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.ahoy_messages")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE ahoy_messages
          ALTER COLUMN id TYPE int,
          ALTER COLUMN user_id TYPE int,
          ALTER COLUMN feedback_message_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.articles")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE articles
          ALTER COLUMN id TYPE int,
          ALTER COLUMN user_id TYPE int,
          ALTER COLUMN second_user_id TYPE int,
          ALTER COLUMN third_user_id TYPE int,
          ALTER COLUMN organization_id TYPE int,
          ALTER COLUMN collection_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.notifications")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE notifications
          ALTER COLUMN id TYPE int,
          ALTER COLUMN notifiable_id TYPE int,
          ALTER COLUMN user_id TYPE int
      SQL
    )
  end
end
