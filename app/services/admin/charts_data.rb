module Admin
  class ChartsData
    def initialize(length = 7)
      @length = length
    end

    def call
      period = (@length + 1).days.ago..1.day.ago
      previous_period = (@length * 2).days.ago..(@length + 1).days.ago

      grouped_posts = Article.where(published_at: period).group("DATE(published_at)").size
      grouped_comments = Comment.where(created_at: period).group("DATE(created_at)").size
      grouped_reactions = Reaction.where(created_at: period).group("DATE(created_at)").size
      grouped_users = User.where(registered_at: period).group("DATE(registered_at)").size

      days_range = @length.downto(1)
      posts_values = days_range.map { |n| grouped_posts[n.days.ago.to_date] || 0 }
      comments_values = days_range.map { |n| grouped_comments[n.days.ago.to_date] || 0 }
      reactions_values = days_range.map { |n| grouped_reactions[n.days.ago.to_date] || 0 }
      new_members_values = days_range.map { |n| grouped_users[n.days.ago.to_date] || 0 }

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
  end
end