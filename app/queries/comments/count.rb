# find comments count for an article based on our display rules for signed in users
# the count includes both comments displayed as usual (text), comments displayed as "deleted" or "hidden by post author"
# the count doesn't include comments not displayed at all (childless comments with score below HIDE_THRESHOLD)

module Comments
  class Count
    attr_reader :article

    def initialize(article)
      @article = article
    end

    def call
      # comments that are not displayed at all (not even a "comment deleted" message):
      # with the score below hiding threshold and w/o children
      count_sql = "SELECT COUNT(id) FROM comments c1 WHERE score < ? AND commentable_id = ? " \
                  "AND commentable_type = ? AND NOT EXISTS " \
                  "(SELECT 1 FROM comments c2 WHERE c2.ancestry LIKE CONCAT('%/', c1.id::varchar(255)) " \
                  "OR c2.ancestry = c1.id::varchar(255))"
      san_count_sql = Comment.sanitize_sql([count_sql, Comment::HIDE_THRESHOLD, @article.id, "Article"])
      hidden_comments_cnt = Comment.count_by_sql(san_count_sql)
      article.comments_count - hidden_comments_cnt
    end
  end
end
