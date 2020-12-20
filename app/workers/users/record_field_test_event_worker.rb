module Users
  class RecordFieldTestEventWorker
    include Sidekiq::Worker
    include FieldTest::Helpers

    sidekiq_options queue: :low_priority, retry: 10

    def perform(user_id, goal)
      @user = User.find_by(id: user_id)
      return unless user

      @experiment = :feed_top_articles_query # Current experiment running
      case goal
      when "user_creates_pageview"
        pageview_goal(7.days.ago, "DATE(created_at)", 4, "user_views_article_four_days_in_week")
        pageview_goal(24.hours.ago, "DATE_PART('hour', created_at)", 4, "user_views_article_four_hours_in_day")
        pageview_goal(14.days.ago, "DATE(created_at)", 9, "user_views_article_nine_days_in_two_week")
        pageview_goal(5.days.ago, "DATE_PART('hour', created_at)", 12, "user_views_article_twelve_hours_in_five_days")
      else
        field_test_converted(experiment, participant: user, goal: goal)
      end
    end

    private

    def pageview_goal(time_start, group_value, min_count, goal_name)
      past_week_page_view_counts = @user.page_views.where("created_at > ?", time_start)
        .group(group_value).count.values
      past_week_page_view_counts.delete(0)
      return unless past_week_page_view_counts.size >= min_count

      field_test_converted(@experiment, participant: user, goal: goal_name)
    end
  end
end
