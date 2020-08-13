class ChangeTagIdsToBigints < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.tag_adjustments")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE tag_adjustments
          ALTER COLUMN article_id TYPE bigint,
          ALTER COLUMN user_id TYPE bigint,
          ALTER COLUMN tag_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.taggings")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE taggings
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN tag_id TYPE bigint,
          ALTER COLUMN taggable_id TYPE bigint,
          ALTER COLUMN tagger_id TYPE bigint
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.tags")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE tags
          ALTER COLUMN id TYPE bigint,
          ALTER COLUMN badge_id TYPE bigint,
          ALTER COLUMN mod_chat_channel_id TYPE bigint
      SQL
    )
  end

  def down
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.tag_adjustments")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE tag_adjustments
          ALTER COLUMN article_id TYPE int,
          ALTER COLUMN user_id TYPE int,
          ALTER COLUMN tag_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.taggings")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE taggings
          ALTER COLUMN id TYPE int,
          ALTER COLUMN tag_id TYPE int,
          ALTER COLUMN taggable_id TYPE int,
          ALTER COLUMN tagger_id TYPE int
      SQL
    )

    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS hypershield.tags")
    ActiveRecord::Base.connection.execute(
      <<-SQL
        ALTER TABLE tags
          ALTER COLUMN id TYPE int,
          ALTER COLUMN badge_id TYPE int,
          ALTER COLUMN mod_chat_channel_id TYPE int
      SQL
    )
  end
end
