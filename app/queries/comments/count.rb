# used to ...
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
        count_sql = "select count(id) from comments c1 where score < ? and commentable_id = ? and commentable_type = ? and not exists (select 1 from comments c2 where c2.ancestry = c1.id::varchar(255))"
        san_count_sql = Comment.sanitize_sql([count_sql, Comment::HIDE_THRESHOLD, @article.id, "Article"])
        hidden_comments_cnt = Comment.count_by_sql(san_count_sql)
        article.comments_count - hidden_comments_cnt
      else
        # for signed out users we hide all negative comments and their children
        article.comments_count

        # negative_comments = article.comments.where("score < 0").roots
        # negative_comment_descendants = negative_comments.descend
      end
    end
  end
end
