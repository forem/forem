# find comments count for an article based on our display rules for signed in users
# the count includes both comments displayed as usual (text), comments displayed as "deleted" or "hidden by post author"
# the count doesn't include comments not displayed at all, which are childless comments that are either:
#   - scored below HIDE_THRESHOLD (spam/low quality with no replies), or
#   - soft-deleted via admin_delete (deleted = true with no replies)
# Note: soft-deleted comments WITH children are counted because they render as a "[deleted]" placeholder.

module Comments
  class Count
    def self.call(...)
      new(...).call
    end

    def initialize(article, recalculate: false)
      @article = article
      @recalculate = recalculate
    end

    def call
      if recalculate || article.displayed_comments_count.nil?
        # A comment is completely invisible (not even shown as "[deleted]") when it is childless AND either:
        #   (a) its score is below HIDE_THRESHOLD, or
        #   (b) it was soft-deleted with deleted = true (e.g. via admin_delete on a childless comment).
        # Soft-deleted comments that DO have children are still visible as "[deleted]" placeholders,
        # so those are intentionally included in the displayed count.
        # A comment has children when some ancestry on the article ends with its id (the last ancestry
        # segment is the direct parent). Collecting those parent ids once lets Postgres probe a hashed
        # subplan, instead of rescanning every comment on the article with a LIKE per candidate.
        # The regex always matches, so the subquery never yields NULL and NOT IN is safe.
        count_sql = "SELECT COUNT(id) - COUNT(id) FILTER (" \
                    "WHERE (score < ? OR deleted = TRUE) AND c1.id::varchar(255) NOT IN " \
                    "(SELECT substring(c2.ancestry from '[^/]*$') FROM comments c2 " \
                    "WHERE c2.commentable_id = ? AND c2.commentable_type = ? AND c2.ancestry IS NOT NULL)" \
                    ") FROM comments c1 WHERE commentable_id = ? AND commentable_type = ?"
        san_count_sql = Comment.sanitize_sql([count_sql, Comment::HIDE_THRESHOLD, @article.id, "Article",
                                              @article.id, "Article"])
        displayed_comments_count = Comment.count_by_sql(san_count_sql)
        if article.displayed_comments_count != displayed_comments_count
          article.update_column(:displayed_comments_count, displayed_comments_count)
        end
      end
      article.displayed_comments_count
    end

    private

    attr_reader :article, :recalculate
  end
end
