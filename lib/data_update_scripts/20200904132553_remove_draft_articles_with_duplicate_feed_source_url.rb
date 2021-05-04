module DataUpdateScripts
  class RemoveDraftArticlesWithDuplicateFeedSourceUrl
    def run
      # Currently there are duplicate draft articles in the DB with the same feed_source_url.

      # This statement deletes all draft articles in excess found to be duplicate over feed_source_url,
      # excluding those whose body_markdown is different from the other duplicate occurrences
      # result_same_body = ActiveRecord::Base.connection.execute(
      #   <<-SQL,
      #     WITH duplicates_draft_articles AS
      #         (SELECT id
      #          FROM
      #              (SELECT id,
      #                      published,
      #                      body_markdown,
      #                      LAG(body_markdown, 1) OVER(PARTITION BY feed_source_url
      #                                                 ORDER BY id ASC) AS previous_body_markdown,
      #                      ROW_NUMBER() OVER(PARTITION BY feed_source_url
      #                                        ORDER BY id ASC) AS row_number
      #               FROM articles
      #               WHERE feed_source_url IS NOT NULL ) duplicates
      #          WHERE duplicates.row_number > 1
      #              AND published = 'f' -- drafts
      #              AND body_markdown = previous_body_markdown -- with the same body
      #      )
      #     DELETE
      #     FROM articles
      #     WHERE id IN (SELECT id FROM duplicates_draft_articles) RETURNING id;
      #   SQL
      # )
      #
      # Now that all duplicates with the same body are gone, we need to deal with duplicate feed source URLs
      # with different bodies.
      # We thus select the oldest for removal preserving the most recent one
      # result_different_bodies = ActiveRecord::Base.connection.execute(
      #   <<-SQL,
      #     WITH duplicates_draft_articles AS
      #         (SELECT id
      #          FROM
      #              (SELECT id,
      #                      published,
      #                      body_markdown,
      #                      LAG(body_markdown, 1) OVER(PARTITION BY feed_source_url
      #                                                 ORDER BY created_at DESC) AS previous_body_markdown,
      #                      ROW_NUMBER() OVER(PARTITION BY feed_source_url
      #                                        ORDER BY created_at DESC) AS row_number
      #               FROM articles
      #               WHERE feed_source_url IS NOT NULL ) duplicates
      #          WHERE duplicates.row_number > 1
      #              AND published = 'f' -- drafts
      #              AND body_markdown != previous_body_markdown -- with different bodies
      #      )
      #     DELETE
      #     FROM articles
      #     WHERE id IN (SELECT id FROM duplicates_draft_articles) RETURNING id;
      #   SQL
      # )
      #
      # result_same_body_ids = result_same_body.map { |row| row["id"] }
      # result_different_bodies_ids = result_different_bodies.map { |row| row["id"] }

      # Remove all articles from Elasticsearch
      # (result_same_body_ids + result_different_bodies_ids).each do |id|
      #   Search::RemoveFromIndexWorker.perform_in(5.seconds, "Search::FeedContent", "article_#{id}")
      # end

      # Store deleted IDs temporarily in Redis for safe keeping
      # Rails.cache.write(
      #   "DataUpdateScripts::RemoveDraftArticlesWithDuplicateFeedSourceUrl::SameBody",
      #   result_same_body_ids,
      #   expires_in: 2.weeks,
      # )
      # Rails.cache.write(
      #   "DataUpdateScripts::RemoveDraftArticlesWithDuplicateFeedSourceUrl::DifferentBodies",
      #   result_same_body_ids,
      #   expires_in: 2.weeks,
      # )
    end
  end
end
