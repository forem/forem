class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  before_action :fetch_and_authorize_user, except: :analytics
  before_action :set_source, only: %i[subscriptions]
  before_action -> { limit_per_page(default: 80, max: 1000) }, except: %i[show analytics]

  def show
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

    @articles = @articles.sorting(params[:sort]).decorate
    @articles = Kaminari.paginate_array(@articles).page(params[:page]).per(50)
  end

  def following_tags
    @followed_tags = @user.follows_by_type("ActsAsTaggableOn::Tag")
      .order(points: :desc).includes(:followable).limit(@follows_limit)
  end

  def following_users
    @follows = @user.follows_by_type("User")
      .order(created_at: :desc).includes(:followable).limit(@follows_limit)
  end

  def following_organizations
    @followed_organizations = @user.follows_by_type("Organization")
      .order(created_at: :desc).includes(:followable).limit(@follows_limit)
  end

  def following_podcasts
    @followed_podcasts = @user.follows_by_type("Podcast")
      .order(created_at: :desc).includes(:followable).limit(@follows_limit)
  end

  def followers
    @follows = Follow.followable_user(@user.id)
      .includes(:follower).order(created_at: :desc).limit(@follows_limit)
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

  def limit_per_page(default:, max:)
    per_page = (params[:per_page] || default).to_i
    @follows_limit = [per_page, max].min
  end
end
