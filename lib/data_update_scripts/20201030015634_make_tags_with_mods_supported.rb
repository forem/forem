module DataUpdateScripts
  class MakeTagsWithModsSupported
    def run
      ActiveRecord::Base.connection.execute(<<~SQL.squish)
        WITH unsupported_tags_with_mods_ids AS (
          SELECT
            tags.id
          FROM
            tags
            JOIN roles ON (roles.name = 'tag_moderator'
                AND resource_id = tags.id)
          WHERE
            supported = FALSE)
        UPDATE
          tags
        SET
          supported = TRUE
        FROM
          unsupported_tags_with_mods_ids AS cte
        WHERE
          tags.id = cte.id;
      SQL
    end
  end
end
