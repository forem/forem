module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
      @open_abuse_reports_count =
        FeedbackMessage.open_abuse_reports.size

      @length = params[:period] || 7
      @period = @length.days.ago..Time.current
      @previous_period = (@length * 2).days.ago..@length.days.ago
      @labels = (0..6).map { |n| n.days.ago.strftime("%b %d") }

      @analytics = [
        ["Posts", Article.where(published_at: @period).size, Article.where(published_at: @previous_period).size,
         [0, 1, 2, 3, 4, 5, 6]],
        ["Comments", Comment.where(created_at: @period).size, Comment.where(created_at: @previous_period).size,
         [0, 1, 2, 3, 4, 5, 6]],
        ["Reactions", Reaction.where(created_at: @period).size, Reaction.where(created_at: @previous_period).size,
         [0, 1, 2, 3, 4, 5, 6]],
        ["New members", User.where(registered_at: @period).size, User.where(registered_at: @previous_period).size,
         [0, 1, 2, 3, 4, 5, 6]],
      ]
    end
  end
end
