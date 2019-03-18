class Internal::DogfoodController < Internal::ApplicationController
  layout "internal"

  def index
    usernames = if Rails.env.production?
                  %w[ben jess peter maestromac andy lianafelt]
                else
                  %w[thepracticaldev bendhalpern]
                end

    @team_members = User.where(username: usernames).order(comments_count: :desc)
    user_ids = @team_members.map(&:id)

    @comment_totals_this_week = Comment.
      users_with_number_of_comments(user_ids, Time.zone.today.beginning_of_week)

    @comment_totals_24_hours = Comment.
      users_with_number_of_comments(user_ids, 24.hours.ago)
  end
end
