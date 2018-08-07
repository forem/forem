class Internal::DogfoodController < Internal::ApplicationController
  layout "internal"

  def index
    usernames = if Rails.env.production?
                  ["ben", "jess", "peter", "maestromac", "andy", "lianafelt"]
                else
                  ["thepracticaldev", "bendhalpern"]
                end

    @team_members = User.where(username: usernames)
    @comments_this_week = Comment.where(user_id: @team_members.pluck(:id)).where("created_at > ?", Date.today.beginning_of_week).pluck(:user_id)
    @comment_totals_this_week = frequency(@comments_this_week)
    @comments_24_hours = Comment.where(user_id: @team_members.pluck(:id)).where("created_at > ?", 24.hours.ago).pluck(:user_id)
    @comment_totals_24_hours = frequency(@comments_24_hours)
  end

  def frequency(a)
    a.group_by do |e|
      e
    end.map do |key, values|
      { number_of_comments: values.size, username: User.find(key).username }
    end.sort_by { |hsh| hsh[:number_of_comments] }.reverse!
  end
end
