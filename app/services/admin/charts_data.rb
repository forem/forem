module Admin
  class ChartsData
    def initialize(length = 7)
      @length = length
    end

    def call
      period = @length.days.ago..Time.current
      previous_period = (@length * 2).days.ago..@length.days.ago

      grouped_posts = Article.where(published_at: period).group("DATE(published_at)").size
      grouped_comments = Comment.where(created_at: period).group("DATE(created_at)").size
      grouped_reactions = Reaction.where(created_at: period).group("DATE(created_at)").size
      grouped_users = User.where(registered_at: period).group("DATE(registered_at)").size

      posts_values = (0..@length - 1).map { |n| grouped_posts[n.days.ago.to_date] || 0 }.reverse
      comments_values = (0..@length - 1).map { |n| grouped_comments[n.days.ago.to_date] || 0 }.reverse
      reactions_values = (0..@length - 1).map { |n| grouped_reactions[n.days.ago.to_date] || 0 }.reverse
      new_members_values = (0..@length - 1).map { |n| grouped_users[n.days.ago.to_date] || 0 }.reverse

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