module Users
  # Nightly, batched replacement for the per-page-view conversion that
  # PageView#record_field_test_event used to enqueue (disabled for load).
  # Converts the cumulative "viewed pages on N different days" goals for every
  # recently present participant of the given experiment, once per goal.
  class ConvertPageviewFieldTestGoalsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5, lock: :until_and_while_executing

    PAGEVIEW_DAY_GOALS = {
      "user_views_pages_on_at_least_two_different_days_within_a_week" => { days: 7, min_days: 2 },
      "user_views_pages_on_at_least_four_different_days_within_a_week" => { days: 7, min_days: 4 },
      "user_views_pages_on_at_least_nine_different_days_within_two_weeks" => { days: 14, min_days: 9 }
    }.freeze
    PRESENCE_LOOKBACK = 14.days

    def perform(experiment_name)
      data = FieldTest.config.dig("experiments", experiment_name)
      return if data.nil? || data.key?("winner")

      goals = PAGEVIEW_DAY_GOALS.slice(*Array(data["goals"]))
      return if goals.empty?

      experiment = FieldTest::Experiment.find(experiment_name)
      started_at = data.fetch("started_at").beginning_of_day

      memberships_scope = FieldTest::Membership.where(experiment: experiment_name, participant_type: "User")
      memberships_scope.find_in_batches do |memberships|
        users = User.where(id: memberships.map(&:participant_id))
          .where("last_presence_at >= ?", PRESENCE_LOOKBACK.ago)
          .index_by { |user| user.id.to_s }

        memberships.each do |membership|
          user = users[membership.participant_id]
          next unless user

          convert_goals_for(user, membership, experiment, goals, started_at)
        end
      end
    end

    private

    def convert_goals_for(user, membership, experiment, goals, started_at)
      already_converted = membership.events.where(name: goals.keys).distinct.pluck(:name)
      goals.except(*already_converted).each do |goal, rule|
        since = [rule[:days].days.ago, started_at].max
        distinct_days = user.page_views.where("created_at > ?", since).distinct.count("DATE(created_at)")
        experiment.convert(user, goal: goal) if distinct_days >= rule[:min_days]
      end
    end
  end
end
