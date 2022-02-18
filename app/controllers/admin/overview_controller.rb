module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
      @open_abuse_reports_count =
        FeedbackMessage.open_abuse_reports.size

      # Stolen from feedback_messages_controller.rb and should probably be adjusted...
      @possible_spam_users_count = User.registered.where("length(name) > ?", 30)
        .where("created_at > ?", 48.hours.ago)
        .order(created_at: :desc)
        .select(:username, :name, :id)
        .where.not("username LIKE ?", "%spam_%")
        .size

      # Stolen from priviledged_reactions_controller.rb and should probably be adjusted...
      @flags = Reaction
        .includes(:user, :reactable)
        .privileged_category
      @flags_count = @flags.size
      @flags_posts_count = @flags.where(reactable_type: "Article").size
      @flags_comments_count = @flags.where(reactable_type: "Comment").size
      @flags_users_count = @flags.where(reactable_type: "User").size

      # Analytics
      @length = params[:period] || 7
      @length = @length.to_i
      @period = @length.days.ago..Time.current
      @previous_period = (@length * 2).days.ago..@length.days.ago
      @labels = (0..@length - 1).map { |n| n.days.ago.strftime("%b %d") }.reverse

      @grouped_posts = Article.where(published_at: @period).group("DATE(published_at)").size
      @grouped_comments = Comment.where(created_at: @period).group("DATE(created_at)").size
      @grouped_reactions = Reaction.where(created_at: @period).group("DATE(created_at)").size
      @grouped_users = User.where(registered_at: @period).group("DATE(registered_at)").size

      @posts_values = (0..@length - 1).map { |n| @grouped_posts[n.days.ago.to_date] || 0 }.reverse
      @comments_values = (0..@length - 1).map { |n| @grouped_comments[n.days.ago.to_date] || 0 }.reverse
      @reactions_values = (0..@length - 1).map { |n| @grouped_reactions[n.days.ago.to_date] || 0 }.reverse
      @new_members_values = (0..@length - 1).map { |n| @grouped_users[n.days.ago.to_date] || 0 }.reverse

      @analytics = [
        ["Posts", @posts_values.sum, Article.where(published_at: @previous_period).size,
         @posts_values],
        ["Comments", @comments_values.sum, Comment.where(created_at: @previous_period).size,
         @comments_values],
        ["Reactions", @reactions_values.sum, Reaction.where(created_at: @previous_period).size,
         @reactions_values],
        ["New members", @new_members_values.sum, User.where(registered_at: @previous_period).size,
         @new_members_values],
      ]
    end
  end
end
