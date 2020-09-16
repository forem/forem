module DataUpdateScripts
  class RemoveDraftArticlesWithDuplicateUserIdTitleBodyMarkdown
    def run
      # Currently there are duplicate draft articles in the DB with the same body_markdown, title, user_id combination

      # This statement deletes all draft articles in excess found to be duplicate over those three columns
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          WITH duplicates_draft_articles AS
              (SELECT id
               FROM
                   (SELECT id,
                           published,
                           body_markdown,
                           title,
                           user_id,
                           ROW_NUMBER() OVER(PARTITION BY user_id, title, body_markdown
                                             ORDER BY id ASC) AS row_number
                    FROM articles) duplicates
               WHERE duplicates.row_number > 1
                   AND published = 'f' -- drafts
           )
          DELETE
          FROM articles
          WHERE id IN
                  (SELECT id
                   FROM duplicates_draft_articles) RETURNING id;
        SQL
      )
    end
  end
end
