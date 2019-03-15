class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  after_action :verify_authorized

  def show
    @user = if params[:username] && current_user.any_admin?
              User.find_by_username(params[:username])
            else
              current_user
            end
    authorize (@user || User), :dashboard_show?
    if params[:which] == "following" || params[:which] == "following_users"
      @follows = @user.follows_by_type("User").
        order("created_at DESC").includes(:followable).limit(80)
      @followed_tags = @user.follows_by_type("ActsAsTaggableOn::Tag").
        order("points DESC").includes(:followable).limit(80)
    elsif params[:which] == "user_followers"
      @follows = Follow.where(followable_id: @user.id, followable_type: "User").
        includes(:follower).order("created_at DESC").limit(80)
    elsif params[:which] == "organization_user_followers"
      @follows = Follow.where(followable_id: @user.organization_id, followable_type: "Organization").
        includes(:follower).order("created_at DESC").limit(80)
    elsif @user&.organization && @user&.org_admin && params[:which] == "organization"
      @articles = @user.organization.articles.order("created_at DESC").decorate
    elsif @user
      @articles = @user.articles.order("created_at DESC").decorate
    end
    # Updates analytics in background if appropriate:
    ArticleAnalyticsFetcher.new.delay.update_analytics(current_user.id) if @articles
  end

  def pro
    authorize current_user, :pro_user?
    @current_user_article_ids = current_user.articles.pluck(:id)
    @this_week_reactions = ChartDecorator.decorate(Reaction.where(reactable_id: @current_user_article_ids, reactable_type: "Article").where("created_at > ?", 1.week.ago).order("created_at ASC"))
    @this_week_reactions_count = @this_week_reactions.size
    @last_week_reactions_count = Reaction.where(reactable_id: @current_user_article_ids, reactable_type: "Article").where("created_at > ? AND created_at < ?", 2.weeks.ago, 1.week.ago).size
    @this_month_reactions_count = Reaction.where(reactable_id: @current_user_article_ids, reactable_type: "Article").where("created_at > ?", 1.month.ago).size
    @last_month_reactions_count = Reaction.where(reactable_id: @current_user_article_ids, reactable_type: "Article").where("created_at > ? AND created_at < ?", 2.months.ago, 1.months.ago).size
    @this_week_comments_count = Comment.where(commentable_id: @current_user_article_ids, commentable_type: "Article").where("created_at > ?", 1.week.ago).size
    @this_week_comments = ChartDecorator.decorate(Comment.where(commentable_id: @current_user_article_ids, commentable_type: "Article").where("created_at > ?", 1.week.ago))
    @last_week_comments_count = @this_week_comments.size
    @this_month_comments_count = Comment.where(commentable_id: @current_user_article_ids, commentable_type: "Article").where("created_at > ?", 1.month.ago).size
    @last_month_comments_count = Comment.where(commentable_id: @current_user_article_ids, commentable_type: "Article").where("created_at > ? AND created_at < ?", 2.months.ago, 1.months.ago).size
    @this_week_followers_count = Follow.where(followable_id: current_user.id, followable_type: "User").where("created_at > ?", 1.week.ago).size
    @last_week_followers_count = Follow.where(followable_id: current_user.id, followable_type: "User").where("created_at > ? AND created_at < ?", 2.weeks.ago, 1.week.ago).size
    @this_month_followers_count = Follow.where(followable_id: current_user.id, followable_type: "User").where("created_at > ?", 1.month.ago).size
    @last_month_followers_count = Follow.where(followable_id: current_user.id, followable_type: "User").where("created_at > ? AND created_at < ?", 2.months.ago, 1.months.ago).size
    @reactors = User.
      where(id: Reaction.where(reactable_id: @current_user_article_ids, reactable_type: "Article").order("created_at DESC").limit(100).pluck(:user_id))
  end
end
