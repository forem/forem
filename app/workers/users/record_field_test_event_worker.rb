module Users
  class RecordFieldTestEventWorker
    include Sidekiq::Worker
    include FieldTest::Helpers

    sidekiq_options queue: :low_priority, retry: 10

    def perform(user_id, experiment, goal)
      user = User.find(user_id)

      if goal == "user_views_article_four_days_in_week"
        determine_weekly_pageview_goal(user, experiment)
      elsif goal == "user_views_article_four_of_past_7_hours"
        determine_past_seven_hours_pageview_goal(user, experiment)
      else
        field_test_converted(experiment, participant: user, goal: goal)
      end
    end

    private

    def determine_weekly_pageview_goal(user, experiment)
      past_week_page_view_counts = user.page_views.where("created_at > ?", 7.days.ago).
        group("DATE(created_at)").count.values
      past_week_page_view_counts.delete(0)
      return unless past_week_page_view_counts.size > 3

      field_test_converted(experiment, participant: user, goal: "user_views_article_four_days_in_week")
    end

    def determine_past_seven_hours_pageview_goal(user, experiment)
      past_seven_hours_counts = user.page_views.where("created_at > ?", 7.hours.ago).
        group("DATE_PART('hour', created_at)").count.values
      past_seven_hours_counts.delete(0)
      return unless past_seven_hours_counts.size > 3

      field_test_converted(experiment, participant: user, goal: "user_views_article_four_of_past_7_hours")
    end
  end
end
