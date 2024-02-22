# find comments count for an article based on our display rules for signed in and signed out users
module Comments
  class Count
    attr_reader :article, :user_signed_in

    def initialize(article, user_signed_in = false)
      @article = article
      @user_signed_in = user_signed_in
    end

    # returns comments_count according to user_signed in or not + number of comments
    # that are not displayed because of the low score and being childless
    # doesn't takes into account: comments deleted by user, hidden by "hidden" field, low-score comments with children
    # because they are still displayed as "comment deleted" or "comment hidden" message
    def call
      if user_signed_in
        # comments that are not displayed at all (not even a "comment deleted" message):
        # with the score below hiding threshold and w/o children
        count_sql = "SELECT COUNT(id) FROM comments c1 WHERE score < ? AND commentable_id = ?"\
        " AND commentable_type = ? AND NOT EXISTS"\
        " (SELECT 1 FROM comments c2 WHERE c2.ancestry LIKE CONCAT('%/', c1.id::varchar(255))"\
        " OR c2.ancestry = c1.id::varchar(255))"
        san_count_sql = Comment.sanitize_sql([count_sql, Comment::HIDE_THRESHOLD, @article.id, "Article"])
        hidden_comments_cnt = Comment.count_by_sql(san_count_sql)
        article.comments_count - hidden_comments_cnt
      else
        # for signed out users we hide all negative comments and their children
        negative_comments_ids = article.comments.where("score < 0").roots.pluck(:id).map(&:to_s)
        percented_array = negative_comments_ids.map{ |id| "#{id}/%" }
        descendants_count = Comment.where("ancestry LIKE ANY ( array[?] ) OR ancestry in (?)", percented_array, negative_comments_ids).count
        article.comments_count - negative_comments_ids.count - descendants_count
      end
    end
  end
end
