class AnalyticsService
  def initialize(user_or_org, options = {})
    @options = options
    @user_or_org = user_or_org

    @article_data ||= Article.where("#{user_or_org.class.name.downcase}_id" => user_or_org.id, published: true)
    @article_ids ||= @article_data.pluck(:id)
    if options[:start]
      @reaction_data ||= Reaction.where(reactable_id: article_ids, reactable_type: "Article").where("created_at >= ? AND created_at <= ? AND points > 0", start_date.in_time_zone, end_date.in_time_zone)
      @comment_data ||= Comment.where(commentable_id: article_ids, commentable_type: "Article").where("created_at >= ? AND created_at <= ? AND score > 0", start_date.in_time_zone, end_date.in_time_zone)
      @follow_data ||= Follow.where(followable_type: user_or_org.class.name, followable_id: user_or_org.id)
      @page_view_data ||= PageView.where(article_id: article_ids).where("created_at > ? AND created_at < ?", start_date.in_time_zone, end_date.in_time_zone)
    else
      @reaction_data ||= Reaction.where(reactable_id: article_ids, reactable_type: "Article").where("points > 0")
      @comment_data ||= Comment.where(commentable_id: article_ids, commentable_type: "Article").where("score > 0")
      @follow_data ||= Follow.where(followable_type: user_or_org.class.name, followable_id: user_or_org.id)
      @page_view_data ||= PageView.where(article_id: article_ids)
    end
  end

  def totals
    total_views = article_data.sum(:page_views_count)
    logged_in_page_view_data = page_view_data.select { |pv| pv.user_id.present? }
    average_read_time_in_seconds = logged_in_page_view_data.size.positive? ? logged_in_page_view_data.sum(&:time_tracked_in_seconds) / logged_in_page_view_data.size : 0

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
    final_hash = {}

    dates.each do |date|
      string_date = date.strftime("%a, %m/%d")
      reaction_data_of_date = reaction_data.select { |rxn| rxn.created_at.beginning_of_day.to_i == date.to_i }
      logged_in_page_view_data = page_view_data.select { |pv| pv.created_at.beginning_of_day.to_i == date.to_i && pv.user_id.present? }
      average_read_time_in_seconds = logged_in_page_view_data.size.positive? ? logged_in_page_view_data.sum(&:time_tracked_in_seconds) / logged_in_page_view_data.size : 0
      total_views = page_view_data.select { |pv| pv.created_at.beginning_of_day.to_i == date.to_i }.sum(&:counts_for_number_of_views)

      final_hash[string_date] = {
        comments: {
          total: comment_data.count { |c| c.created_at.beginning_of_day.to_i == date.to_i }
        },
        reactions: {
          total: reaction_data_of_date.count,
          like: reaction_data_of_date.count { |rxn| rxn.category == "like" },
          readinglist: reaction_data_of_date.count { |rxn| rxn.category == "readinglist" },
          unicorn: reaction_data_of_date.count { |rxn| rxn.category == "unicorn" }
        },
        page_views: {
          total: total_views,
          total_read_time_in_seconds: average_read_time_in_seconds * total_views,
          average_read_time_in_seconds: average_read_time_in_seconds
        },
        follows: {
          total: follow_data.count { |f| f.created_at.beginning_of_day.to_i == date.to_i }
        }
      }
    end

    final_hash
  end

  private

  attr_reader :options, :user_or_org, :article_data, :article_ids, :reaction_data, :comment_data, :follow_data, :page_view_data

  def start_date
    options[:start].to_datetime.beginning_of_day
  end

  def end_date
    if options[:end].present?
      options[:end].to_datetime.end_of_day
    else
      DateTime.current.end_of_day
    end
  end

  def dates
    date_range = (end_date - start_date.beginning_of_day).to_i
    dates_array = []
    date_range.times do |index|
      dates_array.push(start_date + index.days)
    end
    dates_array.push(end_date)
  end
end
