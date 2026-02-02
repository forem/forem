module Admin
  class StatsData
    def initialize(period = 7)
      @period = period
    end

    def call
      time_range = @period.days.ago.beginning_of_day..Time.current

      {
        published_posts: Article.where(published_at: time_range).count,
        comments: Comment.where(created_at: time_range).count,
        public_reactions: Reaction.public_category.where(created_at: time_range).count,
        new_users: User.where(registered_at: time_range).count,
        period: @period
      }
    end
  end
end

