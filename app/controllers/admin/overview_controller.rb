module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
      @open_abuse_reports_count =
        FeedbackMessage.open_abuse_reports.size

      @length = params[:period] || 7
      @length = @length.to_i
      @period = @length.days.ago..Time.current
      @previous_period = (@length * 2).days.ago..@length.days.ago
      @labels = (0..@length - 1).map { |n| n.days.ago.strftime("%b %d") }.reverse

      @posts_values = (0..@length - 1).map { |n| Article.where(published_at: n.days.ago.all_day).size }.reverse
      @comments_values = (0..@length - 1).map { |n| Comment.where(created_at: n.days.ago.all_day).size }.reverse
      @reactions_values = (0..@length - 1).map { |n| Reaction.where(created_at: n.days.ago.all_day).size }.reverse
      @new_members_values = (0..@length - 1).map { |n| User.where(registered_at: n.days.ago.all_day).size }.reverse

      @analytics = [
        ["Posts", Article.where(published_at: @period).size, Article.where(published_at: @previous_period).size,
         @posts_values],
        ["Comments", Comment.where(created_at: @period).size, Comment.where(created_at: @previous_period).size,
         @comments_values],
        ["Reactions", Reaction.where(created_at: @period).size, Reaction.where(created_at: @previous_period).size,
         @reactions_values],
        ["New members", User.where(registered_at: @period).size, User.where(registered_at: @previous_period).size,
         @new_members_values],
      ]
    end
  end
end
