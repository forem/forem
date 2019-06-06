class AnalyticsService
  def initialize(user_or_org, start_date: "", end_date: "", article_id: nil)
    @user_or_org = user_or_org
    @article_id = article_id
    @start_date = Time.zone.parse(start_date.to_s)&.beginning_of_day
    @end_date = Time.zone.parse(end_date.to_s)&.end_of_day || Time.current.end_of_day

    load_data
  end

  def totals
    {
      comments: { total: comment_data.size },
      reactions: reactions_totals,
      follows: { total: follow_data.size },
      page_views: page_views_totals
    }
  end

  def grouped_by_day
    return {} unless start_date && end_date

    result = {}

    # 1. calculate all stats using group queries
    comments_stats_per_day = calculate_comments_stats_per_day(comment_data)
    follows_stats_per_day = calculate_follows_stats_per_day(follow_data)

    # 2. build the final hash, one per each day
    (start_date.to_date..end_date.to_date).each do |date|
      iso_date = date.to_s(:iso)
      result[iso_date] = cached_data_for_date(date)

      result[iso_date].merge!(
        comments: { total: comments_stats_per_day[iso_date] || 0 },
        follows: { total: follows_stats_per_day[iso_date] || 0 },
      )
    end

    result
  end

  private

  attr_reader :user_or_org, :start_date, :end_date, :article_data, :reaction_data, :comment_data, :follow_data, :page_view_data

  def load_data
    @article_data = Article.published.where("#{user_or_org.class.name.downcase}_id" => user_or_org.id)
    if @article_id
      # check article_id is published and belongs to the user/org
      @article_data = @article_data.where(id: @article_id)
      raise ArgumentError unless @article_data.exists?

      article_ids = [@article_id]
    else
      article_ids = @article_data.pluck(:id)
    end

    if @start_date && @end_date
      @reaction_data = Reaction.where(reactable_id: article_ids, reactable_type: "Article").
        where(created_at: @start_date..@end_date).
        where("points > 0")
      @comment_data = Comment.where(commentable_id: article_ids, commentable_type: "Article").
        where(created_at: @start_date..@end_date).
        where("score > 0")
      @page_view_data = PageView.where(article_id: article_ids).where(created_at: @start_date..@end_date)
    else
      @reaction_data = Reaction.where(reactable_id: article_ids, reactable_type: "Article").where("points > 0")
      @comment_data = Comment.where(commentable_id: article_ids, commentable_type: "Article").where("score > 0")
      @page_view_data = PageView.where(article_id: article_ids)
    end

    @follow_data = Follow.where(followable_type: user_or_org.class.name, followable_id: user_or_org.id)
  end

  def reactions_totals
    # NOTE: the order of the keys needs to be the same as the one of the counts
    keys = %i[total like readinglist unicorn]
    counts = reaction_data.pluck(
      Arel.sql("COUNT(*)"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'like')"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'readinglist')"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'unicorn')"),
    ).first

    # this transforms the counts, eg. [1, 0, 1, 0]
    # in a hash, eg. {total: 1, like: 0, readinglist: 1, unicorn: 0}
    keys.zip(counts).to_h
  end

  def page_views_totals
    total_views = article_data.sum(:page_views_count)
    logged_in_page_view_data = page_view_data.where.not(user_id: nil)
    average_read_time_in_seconds = average_read_time(logged_in_page_view_data)

    {
      total: total_views,
      average_read_time_in_seconds: average_read_time_in_seconds,
      total_read_time_in_seconds: average_read_time_in_seconds * total_views
    }
  end

  def average_read_time(page_view_data)
    average = page_view_data.pluck(Arel.sql("AVG(time_tracked_in_seconds)")).first
    # average is returned as a BigDecimal, it needs to be rounded to an integer
    (average || 0).round
    # page_view_data.size.positive? ? page_view_data.sum(:time_tracked_in_seconds) / page_view_data.size : 0
  end

  def calculate_comments_stats_per_day(comment_data)
    # AR returns a hash with date => count, we transform it using ISO dates for convenience
    comment_data.group("date(created_at)").count.transform_keys(&:iso8601)
  end

  def calculate_follows_stats_per_day(follow_data)
    # AR returns a hash with date => count, we transform it using ISO dates for convenience
    follow_data.group("date(created_at)").count.transform_keys(&:iso8601)
  end

  def cached_data_for_date(date)
    expiration_date = if date == Time.current.to_date
                        30.minutes
                      else
                        7.days
                      end

    Rails.cache.fetch("analytics-for-date-#{date}-#{user_or_org.class.name}-#{user_or_org.id}", expires_in: expiration_date) do
      reaction_data_of_date = reaction_data.where("date(created_at) = ?", date)
      logged_in_page_view_data = page_view_data.where("date(created_at) = ?", date).where.not(user_id: nil)
      average_read_time_in_seconds = average_read_time(logged_in_page_view_data)
      total_views = page_view_data.where("date(created_at) = ?", date).sum(:counts_for_number_of_views)

      {
        # comments: {
        #   total: comment_data.where("date(created_at) = ?", date).size
        # },
        reactions: {
          total: reaction_data_of_date.size,
          like: reaction_data_of_date.where("category = ?", "like").size,
          readinglist: reaction_data_of_date.where("category = ?", "readinglist").size,
          unicorn: reaction_data_of_date.where("category = ?", "unicorn").size
        },
        page_views: {
          total: total_views,
          average_read_time_in_seconds: average_read_time_in_seconds,
          total_read_time_in_seconds: average_read_time_in_seconds * total_views
        }
        # follows: {
        #   total: follow_data.where("date(created_at) = ?", date).size
        # }
      }
    end
  end
end
