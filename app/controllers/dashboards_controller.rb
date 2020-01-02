class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  before_action :fetch_and_authorize_user, except: :pro
  before_action -> { limit_per_page(default: 80, max: 1000) }, except: %i[show pro]
  after_action :verify_authorized

  def show
    @current_user_pro = current_user.pro?

    target = @user
    not_authorized if params[:org_id] && !@user.org_admin?(params[:org_id] || @user.any_admin?)

    @organizations = @user.admin_organizations

    if params[:which] == "organization" && params[:org_id] && (@user.org_admin?(params[:org_id]) || @user.any_admin?)
      target = @organizations.find_by(id: params[:org_id])
      @organization = target
    end

    @articles = target.articles.includes(:organization).sorting(params[:sort]).decorate

    # Updates analytics in background if appropriate
    Articles::UpdateAnalyticsWorker.perform_async(current_user.id) if @articles && ApplicationConfig["GA_FETCH_RATE"] < 50 # Rate limit concerned, sometimes we throttle down.
  end

  def following_tags
    @followed_tags = @user.follows_by_type("ActsAsTaggableOn::Tag").
      order("points DESC").includes(:followable).limit(@follows_limit)
  end

  def following_users
    @follows = @user.follows_by_type("User").
      order("created_at DESC").includes(:followable).limit(@follows_limit)
  end

  def following_organizations
    @followed_organizations = @user.follows_by_type("Organization").
      order("created_at DESC").includes(:followable).limit(@follows_limit)
  end

  def following_podcasts
    @followed_podcasts = @user.follows_by_type("Podcast").
      order("created_at DESC").includes(:followable).limit(@follows_limit)
  end

  def followers
    if params[:which] == "user_followers"
      @follows = Follow.where(followable_id: @user.id, followable_type: "User").
        includes(:follower).order("created_at DESC").limit(@follows_limit)
    elsif params[:which] == "organization_user_followers"
      @follows = Follow.where(followable_id: @user.organization_id, followable_type: "Organization").
        includes(:follower).order("created_at DESC").limit(@follows_limit)
    end
  end

  def pro
    @user_or_org = if params[:org_id]
                     org = Organization.find_by(id: params[:org_id])
                     authorize org, :pro_org_user?
                     org
                   else
                     authorize current_user, :pro_user?
                     current_user
                   end
    @organizations = current_user.member_organizations
  end

  private

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
