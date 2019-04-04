class AnalyticsService
  def initialize(user_or_org, start_date: "", end_date: "")
    @user_or_org = user_or_org
    @start_date = Time.zone.parse(start_date.to_s)&.beginning_of_day
    @end_date = Time.zone.parse(end_date.to_s)&.end_of_day || Time.current.end_of_day

    load_data
  end

  def totals
    total_views = article_data.sum(:page_views_count)
    logged_in_page_view_data = page_view_data.where.not(user_id: nil)
    average_read_time_in_seconds = average_read_time(logged_in_page_view_data)

    {
      comments: {
        total: comment_data.size
      },
      reactions: {
        total: reaction_data.size,
        like: reaction_data.count { |rxn| rxn.category == "like" },
        readinglist: reaction_data.count { |rxn| rxn.category == "readinglist" },
        unicorn: reaction_data.count { |rxn| rxn.category == "unicorn" }
      },
      follows: {
        total: follow_data.size
      },
      page_views: {
        total: total_views,
        average_read_time_in_seconds: average_read_time_in_seconds,
        total_read_time_in_seconds: average_read_time_in_seconds * total_views
      }
    }
  end

  def stats_grouped_by_day
    result = {}

    (start_date.to_date..end_date.to_date).each do |date|
      reaction_data_of_date = reaction_data.where("date(created_at) = ?", date)
      logged_in_page_view_data = page_view_data.where("date(created_at) = ?", date).where.not(user_id: nil)
      average_read_time_in_seconds = average_read_time(logged_in_page_view_data)
      total_views = page_view_data.where("date(created_at) = ?", date).sum(:counts_for_number_of_views)

      result[date.to_s(:iso)] = {
        comments: {
          total: comment_data.where("date(created_at) = ?", date).size
        },
        reactions: {
          total: reaction_data_of_date.size,
          like: reaction_data_of_date.where("category = ?", "like").size,
          readinglist: reaction_data_of_date.where("category = ?", "readinglist").size,
          unicorn: reaction_data_of_date.where("category = ?", "unicorn").size
        },
        page_views: {
          total: total_views,
          total_read_time_in_seconds: average_read_time_in_seconds * total_views,
          average_read_time_in_seconds: average_read_time_in_seconds
        },
        follows: {
          total: follow_data.where("date(created_at) = ?", date).size
        }
      }
    end

    result
  end

  private

  attr_reader :user_or_org, :start_date, :end_date, :article_data, :reaction_data, :comment_data, :follow_data, :page_view_data

  def load_data
    @article_data = Article.where("#{user_or_org.class.name.downcase}_id" => user_or_org.id, published: true)
    article_ids = @article_data.pluck(:id)

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

  def average_read_time(page_view_data)
    page_view_data.size.positive? ? page_view_data.sum(:time_tracked_in_seconds) / page_view_data.size : 0
  end
end
