# @note The actions of this class are overloaded with three concerns:
#
#       - the current user
#       - a given user
#       - a given organization
#
#       The implementation details are such that things silently "fallback" to the current user's
#       information.  This fallback happens when we have quasi-policy checks say the current user
#       can't access the given user or given organization.
#
#       [@jeremyf] I'm including these notes for future refactors, as I've spent time trying to
#       improve legibility of the code but there are logical assumptions that require revisiting
#       (hence https://github.com/forem/forem/issues/16931).
class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  before_action :set_agent_sessions_count

  layout false, only: :sidebar

  LIMIT_PER_PAGE_DEFAULT = 80
  LIMIT_PER_PAGE_MAX = 1000
  ARTICLES_PER_PAGE = 25

  def show
    fetch_and_authorize_user
    target = @user
    # NOTE: This is a subtle policy check happening here that we are not encapsulating
    not_authorized if params[:org_id] && !(@user.org_admin?(params[:org_id]) || @user.any_admin?)

    @organizations = @user.admin_organizations

    # NOTE: This logic is a super set of the above not_authorized check
    if params[:which] == "organization" && params[:org_id] && (@user.org_admin?(params[:org_id]) || @user.any_admin?)
      target = @organizations.find_by(id: params[:org_id])
      @organization = target
      @articles = target.articles.from_subforem
    else
      # This redirect assumes that the dashboards#show action renders article specific information.
      # When a user doesn't have articles nor can they create them, we want to send them somewhere
      # else.
      redirect_to dashboard_following_tags_path unless policy(Article).has_existing_articles_or_can_create_new_ones?

      # if the target is a user, we need to eager load the organization
      @articles = target.articles.from_subforem.includes(:organization)
      @articles = params[:state] == "status" ? @articles.statuses : @articles.full_posts
    end

    @reactions_count = @articles.sum(&:public_reactions_count)
    @comments_count = @articles.sum(&:comments_count)
    @page_views_count = @articles.sum(&:page_views_count)

    @articles = @articles.includes(:collection).sorting(params[:sort]).decorate
    @articles = Kaminari.paginate_array(@articles).page(params[:page]).per(ARTICLES_PER_PAGE)
    @collections_count = target.collections.non_empty.count
  end

  def sidebar
    @user = current_user
    @organizations = @user.admin_organizations
    @action = params[:state]
  end

  def following_tags
    fetch_and_authorize_user
    @followed_tags = follows_for_tag(user: @user, order_by: :points)
    @collections_count = collections_count(@user)
  end

  def following_users
    fetch_and_authorize_user
    @follows = follows_for(user: @user, type: "User")
    @collections_count = collections_count(@user)
  end

  def following_organizations
    fetch_and_authorize_user
    @followed_organizations = follows_for(user: @user, type: "Organization")
    @collections_count = collections_count(@user)
  end

  def following_podcasts
    fetch_and_authorize_user
    @followed_podcasts = follows_for(user: @user, type: "Podcast")
    @collections_count = collections_count(@user)
  end

  def followers
    fetch_and_authorize_user
    @follows = Follow.non_suspended("User", @user.id)
      .includes(:follower).order(created_at: :desc).limit(follows_limit)
    @collections_count = collections_count(@user)
  end

  def analytics
    @user_or_org = if params[:org_id]
                     Organization.find(params[:org_id])
                   else
                     current_user
                   end
    authorize(@user_or_org, :analytics?)
    @organizations = current_user.member_organizations
  end

  def subscriptions
    fetch_and_authorize_user
    set_source
    authorize @source
    @subscriptions = @source.user_subscriptions
      .includes(:subscriber).order(created_at: :desc).page(params[:page]).per(100)
  end

  def hidden_tags
    fetch_and_authorize_user
    @hidden_tags = follows_for_tag(user: @user, order_by: :explicit_points, explicit_points: (...0))
    @collections_count = collections_count(@user)
  end

  def feed_imports
    fetch_and_authorize_user
    @feed_sources = @user.feed_sources.includes(:organization, :author).order(:created_at)
    @user_organizations = @user.organizations
    admin_org_ids = OrganizationMembership
      .where(user_id: @user.id, type_of_user: "admin")
      .pluck(:organization_id)
    @org_members_by_org = OrganizationMembership
      .where(organization_id: admin_org_ids)
      .where.not(type_of_user: "pending")
      .includes(:user)
      .group_by(&:organization_id)
      .transform_values { |memberships| memberships.map(&:user) }
    @selected_source = @feed_sources.find_by(id: params[:feed_source_id]) if params[:feed_source_id].present?

    # Determine overall feed status from sources
    if @selected_source
      @feed_status = @selected_source.status
      @feed_url = @selected_source.feed_url
    elsif @feed_sources.any?
      worst = @feed_sources.order(status: :desc).first
      @feed_status = worst.status
      @feed_url = @feed_sources.first.feed_url
    else
      @feed_status = @user.setting&.feed_status
      @feed_url = @user.setting&.feed_url
    end

    logs = @user.feed_import_logs
    logs = logs.for_feed_source(@selected_source.id) if @selected_source

    @feed_import_logs = logs
      .notable
      .recent
      .includes(:feed_source, import_items: :article)
      .page(params[:page])
      .per(ARTICLES_PER_PAGE)

    @routine_logs = logs.routine.recent.includes(:feed_source).limit(20)
    @routine_logs_count = logs.routine.count

    @total_imported = logs.sum(:items_imported)
    @total_skipped = logs.sum(:items_skipped)
    @total_failed = logs.sum(:items_failed)
    @last_successful_import = logs.completed.maximum(:created_at)

    @collections_count = collections_count(@user)
  end

  private

  def set_agent_sessions_count
    @agent_sessions_count = current_user.agent_sessions.count
  end

  def follows_for(user:, type:, order_by: :created_at)
    user.follows_by_type(type).order(order_by => :desc).includes(:followable).limit(follows_limit)
  end

  def follows_for_tag(user:, order_by: :created_at, explicit_points: (0...))
    user.follows_by_type("ActsAsTaggableOn::Tag").order(order_by => :desc)
      .where(explicit_points: explicit_points)
      .includes(:followable)
      .limit(follows_limit)
  end

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
    # NOTE: later we expect @user so the `||` is a bit misleading.
    authorize (@user || User), :dashboard_show?
  end

  def follows_limit(default: LIMIT_PER_PAGE_DEFAULT, max: LIMIT_PER_PAGE_MAX)
    return default unless params.key?(:per_page)

    per_page = params[:per_page].to_i
    return max if per_page > max

    per_page
  end

  def collections_count(user)
    user.collections.non_empty.count
  end
end
