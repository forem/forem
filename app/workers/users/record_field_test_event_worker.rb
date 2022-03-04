module Users
  class RecordFieldTestEventWorker
    include Sidekiq::Worker
    include FieldTest::Helpers

    sidekiq_options queue: :low_priority, retry: 10

    def perform(user_id, goal)
      @user = User.find_by(id: user_id)
      return unless @user
      return unless FieldTest.config["experiments"]

      FieldTest.config["experiments"].each_key do |key|
        @experiment = key.to_sym
        case goal
        # We have special conditional goals for some where we look for past events for commulative wins
        # Otherwise we convert the goal as given.
        when "user_creates_pageview"
          pageview_goal(7.days.ago, "DATE(created_at)", 4,
                        "user_views_pages_on_at_least_four_different_days_within_a_week")
          pageview_goal(24.hours.ago, "DATE_PART('hour', created_at)", 4,
                        "user_views_pages_on_at_least_four_different_hours_within_a_day")
          pageview_goal(14.days.ago, "DATE(created_at)", 9,
                        "user_views_pages_on_at_least_nine_different_days_within_two_weeks")
          pageview_goal(5.days.ago, "DATE_PART('hour', created_at)", 12,
                        "user_views_pages_on_at_least_twelve_different_hours_within_five_days")
        when "user_creates_comment" # comments goal. Only page views and comments are currently active.
          field_test_converted(@experiment, participant: @user, goal: goal) # base single comment goal.
          comment_goal(7.days.ago, "DATE(created_at)", 4,
                       "user_creates_comment_on_at_least_four_different_days_within_a_week")
        else
          field_test_converted(@experiment, participant: @user, goal: goal) # base single comment goal.
        end
      end
    end

    private

    def pageview_goal(time_start, group_value, min_count, goal_name)
      page_view_counts = @user.page_views.where("created_at > ?", time_start)
        .group(group_value).count.values
      page_view_counts.delete(0)
      return unless page_view_counts.size >= min_count

      field_test_converted(@experiment, participant: @user, goal: goal_name)
    end

    def comment_goal(time_start, group_value, min_count, goal_name)
      comment_counts = @user.comments.where("created_at > ?", time_start)
        .group(group_value).count.values
      comment_counts.delete(0)
      return unless comment_counts.size >= min_count

      field_test_converted(@experiment, participant: @user, goal: goal_name)
    end
  end
end
