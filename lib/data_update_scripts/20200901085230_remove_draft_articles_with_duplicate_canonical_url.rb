module DataUpdateScripts
  class RemoveDraftArticlesWithDuplicateCanonicalUrl
    def run
      # Currently there are duplicate draft articles in the DB with the same canonical_url.

      # This statement deletes all draft articles in excess found to be duplicate over canonical_url,
      # excluding those whose body_markdown is different from the other duplicate occurrences
      result = ActiveRecord::Base.connection.execute(
        <<-SQL,
          WITH duplicates_draft_articles AS
              (SELECT id
               FROM
                   (SELECT id,
                           published,
                           body_markdown,
                           LAG(body_markdown, 1) OVER(PARTITION BY canonical_url
                                                      ORDER BY id ASC) AS previous_body_markdown,
                           ROW_NUMBER() OVER(PARTITION BY canonical_url
                                             ORDER BY id ASC) AS row_number
                    FROM articles
                    WHERE canonical_url IS NOT NULL ) duplicates
               WHERE duplicates.row_number > 1
                   AND published = 'f' -- drafts
                   AND body_markdown = previous_body_markdown -- with the same body
           )
          DELETE
          FROM articles
          WHERE id IN (SELECT id FROM duplicates_draft_articles) RETURNING id;
        SQL
      )

      # Sending IDs of deleted articles to Datadog
      result.map { |row| row["id"] }.in_groups_of(1000) do |ids|
        ForemStatsClient.event(
          "DataUpdateScripts::RemoveDraftArticlesWithDuplicateCanonicalUrl",
          "deleted draft articles with the same canonical_url and same body_markdown",
          tags: ids,
        )
      end

      # Now that all duplicates with the same body are gone, we need to deal with duplicate canonical URLs
      # with different bodies.
      # We thus select the oldest for removal preserving the most recent one
      result = ActiveRecord::Base.connection.execute(
        <<-SQL,
          WITH duplicates_draft_articles AS
              (SELECT id
               FROM
                   (SELECT id,
                           published,
                           body_markdown,
                           LAG(body_markdown, 1) OVER(PARTITION BY canonical_url
                                                      ORDER BY created_at DESC) AS previous_body_markdown,
                           ROW_NUMBER() OVER(PARTITION BY canonical_url
                                             ORDER BY created_at DESC) AS row_number
                    FROM articles
                    WHERE canonical_url IS NOT NULL ) duplicates
               WHERE duplicates.row_number > 1
                   AND published = 'f' -- drafts
                   AND body_markdown != previous_body_markdown -- with different bodies
           )
          DELETE
          FROM articles
          WHERE id IN (SELECT id FROM duplicates_draft_articles) RETURNING id;
        SQL
      )

      # Sending IDs of deleted articles to Datadog
      result.map { |row| row["id"] }.in_groups_of(1000) do |ids|
        ForemStatsClient.event(
          "DataUpdateScripts::RemoveDraftArticlesWithDuplicateCanonicalUrl",
          "deleted draft articles with the same canonical_url and different body_markdown",
          tags: ids,
        )
      end
    end
  end
end
