module Admin
  class ChartsData
    def initialize(length = 7)
      @length = length
    end

    def call
      today = Time.now.utc.to_date.beginning_of_day # midnight UTC today
      period_start = today - @length.days
      period = period_start..today
      previous_period_start = period_start - @length.days
      previous_period = previous_period_start..period_start

      grouped_posts = Article.where(published_at: period).group("DATE(published_at)").size
      grouped_comments = Comment.where(created_at: period).group("DATE(created_at)").size
      grouped_reactions = Reaction.where(created_at: period).group("DATE(created_at)").size
      grouped_users = User.where(registered_at: period).group("DATE(registered_at)").size

      days_range = @length.downto(1)
      posts_values = days_range.map { |n| grouped_posts[days_ago(n)] || 0 }
      comments_values = days_range.map { |n| grouped_comments[days_ago(n)] || 0 }
      reactions_values = days_range.map { |n| grouped_reactions[days_ago(n)] || 0 }
      new_members_values = days_range.map { |n| grouped_users[days_ago(n)] || 0 }

      [
        ["Posts", posts_values.sum, Article.where(published_at: previous_period).size,
         posts_values],
        ["Comments", comments_values.sum, Comment.where(created_at: previous_period).size,
         comments_values],
        ["Reactions", reactions_values.sum, Reaction.where(created_at: previous_period).size,
         reactions_values],
        ["New members", new_members_values.sum, User.where(registered_at: previous_period).size,
         new_members_values],
      ]
    end

    def days_ago(offset)
      # we use utc times here for period since the postgresl date() function will too
      # the filtering for published at by period, the conversion to date in the sql side,
      # and grouping by date in the values arrays should use a consistent timeframe
      Time.now.utc.beginning_of_day.to_date - offset.days
    end
  end
end
