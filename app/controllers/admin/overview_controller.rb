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
      @labels = (0..@length - 1).map { |n| n.days.ago.strftime("%b %d") }.reverse
      @analytics = Admin::ChartsData.new(@length).call
    end
  end
end
