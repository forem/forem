class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!

  LIMIT_PER_PAGE_DEFAULT = 80
  LIMIT_PER_PAGE_MAX = 1000
  def show
    fetch_and_authorize_user
    target = @user
    not_authorized if params[:org_id] && !@user.org_admin?(params[:org_id] || @user.any_admin?)

    @organizations = @user.admin_organizations

    if params[:which] == "organization" && params[:org_id] && (@user.org_admin?(params[:org_id]) || @user.any_admin?)
      target = @organizations.find_by(id: params[:org_id])
      @organization = target
      @articles = target.articles
    else
      # if the target is a user, we need to eager load the organization
      @articles = target.articles.includes(:organization)
    end

    @reactions_count = @articles.sum(&:public_reactions_count)
    @page_views_count = @articles.sum(&:page_views_count)

    @articles = @articles.includes(:collection).sorting(params[:sort]).decorate
    @articles = Kaminari.paginate_array(@articles).page(params[:page]).per(50)
    @collections_count = target.collections.non_empty.count
  end

  def following_tags
    fetch_and_authorize_user
    @followed_tags = @user.follows_by_type("ActsAsTaggableOn::Tag")
      .order(points: :desc).includes(:followable).limit(follows_limit)
  end

  def following_users
    fetch_and_authorize_user
    @follows = @user.follows_by_type("User")
      .order(created_at: :desc).includes(:followable).limit(follows_limit)
  end

  def following_organizations
    fetch_and_authorize_user
    @followed_organizations = @user.follows_by_type("Organization")
      .order(created_at: :desc).includes(:followable).limit(follows_limit)
  end

  def following_podcasts
    fetch_and_authorize_user
    @followed_podcasts = @user.follows_by_type("Podcast")
      .order(created_at: :desc).includes(:followable).limit(follows_limit)
  end

  def followers
    fetch_and_authorize_user
    @follows = Follow.followable_user(@user.id)
      .includes(:follower).order(created_at: :desc).limit(follows_limit)
  end

  def analytics
    @user_or_org = if params[:org_id]
                     Organization.find_by(id: params[:org_id])
                   else
                     current_user
                   end
    @organizations = current_user.member_organizations
  end

  def subscriptions
    fetch_and_authorize_user
    set_source
    authorize @source
    @subscriptions = @source.user_subscriptions
      .includes(:subscriber).order(created_at: :desc).page(params[:page]).per(100)
  end

  private

  def set_source
    source_type = UserSubscription::ALLOWED_TYPES.detect { |allowed_type| allowed_type == params[:source_type] }

    not_found unless source_type

    source = source_type.constantize.find_by(id: params[:source_id])
    @source = source || not_found
  end

  def fetch_and_authorize_user
    @user = if params[:username] && current_user.any_admin?
              User.find_by(username: params[:username])
            else
              current_user
            end
    authorize (@user || User), :dashboard_show?
  end

  def follows_limit(default: LIMIT_PER_PAGE_DEFAULT, max: LIMIT_PER_PAGE_MAX)
    return default unless params.key?(:per_page)

    per_page = params[:per_page].to_i
    return max if per_page > max

    per_page
  end
end
