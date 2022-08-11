class ArticlesController < ApplicationController
  include ApplicationHelper

  # NOTE: It seems quite odd to not authenticate the user for the :new action.
  before_action :authenticate_user!, except: %i[feed new]
  before_action :set_article, only: %i[edit manage update destroy stats admin_unpublish admin_featured_toggle]
  # NOTE: Consider pushing this check into the associated Policy.  We could choose to raise a
  #       different error which we could then rescue as part of our exception handling.
  before_action :check_suspended, only: %i[new create update]
  before_action :set_cache_control_headers, only: %i[feed]
  after_action :verify_authorized

  ##
  # [@jeremyf] - My dreamiest of dreams is to move this to the ApplicationController.  But it's very
  #              presence could create some havoc with our edge caching.  So I'm scoping it to the
  #              place where the code is likely to raise an ApplicationPolicy::UserRequiredError.
  #
  #              I still want to enable this, but first want to get things mostly conformant with
  #              existing expectations.  Note, in config/application.rb, we're rescuing the below
  #              excpetion as though it was a Pundit::NotAuthorizedError.
  #
  #              The difference being that rescue_from is an ALWAYS use case.  Whereas the
  #              config/application.rb uses the config.consider_all_requests_local to determine if
  #              we bubble the exception up or handle it.
  #
  # rescue_from ApplicationPolicy::UserRequiredError, with: :respond_with_request_for_authentication

  def feed
    # [@jeremyf] - I am a firm believer that we should check authorization.  However, in this case,
    #              based on our implementation constraints and assumptions, the `#feed` action will
    #              almost certainly be available to everyone (what's in the feed will vary
    #              signficantly).  So while I would love an `authorize(Article)` here, I will make
    #              do with a comment.
    skip_authorization

    @articles = Article.feed.order(published_at: :desc).page(params[:page].to_i).per(12)
    @latest = request.path == latest_feed_path
    @articles = if params[:username]
                  handle_user_or_organization_feed
                elsif params[:tag]
                  handle_tag_feed
                elsif @latest
                  @articles
                    .where("score > ?", Articles::Feeds::Latest::MINIMUM_SCORE)
                    .includes(:user)
                else
                  @articles
                    .with_at_least_home_feed_minimum_score
                    .includes(:user)
                end

    not_found unless @articles&.any?

    set_surrogate_key_header "feed"
    set_cache_control_headers(10.minutes.to_i, stale_while_revalidate: 30, stale_if_error: 1.day.to_i)

    render layout: false, content_type: "application/xml", locals: {
      articles: @articles,
      user: @user,
      tag: @tag,
      latest: @latest,
      allowed_tags: MarkdownProcessor::AllowedTags::FEED,
      allowed_attributes: MarkdownProcessor::AllowedAttributes::FEED,
      scrubber: FeedMarkdownScrubber.new
    }
  end

  # @note The /new path is a unique creature.  We want to ensure that folks coming to the /new with
  #       a prefill of information are first prompted to sign-in, and then given a form that
  #       prepopulates with that pre-fill information.  This is a feature that StackOverflow and
  #       CodePen use to have folks post on Dev.
  def new
    base_editor_assignments

    @article, needs_authorization = Articles::Builder.call(@user, @tag, @prefill)

    if needs_authorization
      authorize(Article)
    else
      skip_authorization

      # We want the query params for the request (as that is where we have the prefill).  The
      # `request.path` excludes the query parameters, so we're going with the `request.url` which
      # includes the parameters.
      store_location_for(:user, request.url)
    end
  end

  def edit
    authorize @article

    @version = @article.has_frontmatter? ? "v1" : "v2"
    @user = @article.user
    @organizations = @user&.organizations
    @user_approved_liquid_tags = Users::ApprovedLiquidTags.call(@user)
  end

  def manage
    authorize @article

    @article = @article.decorate
    @discussion_lock = @article.discussion_lock
    @user = @article.user
    @rating_vote = RatingVote.where(article_id: @article.id, user_id: @user.id).first
    @organizations = @user&.organizations
    # TODO: fix this for multi orgs
    @org_members = @organization.users.pluck(:name, :id) if @organization
  end

  def preview
    authorize Article

    begin
      fixed_body_markdown = MarkdownProcessor::Fixer::FixForPreview.call(params[:article_body])
      parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
      parsed_markdown = MarkdownProcessor::Parser.new(parsed.content, source: Article.new, user: current_user)
      processed_html = parsed_markdown.finalize
    rescue StandardError => e
      @article = Article.new(body_markdown: params[:article_body])
      @article.errors.add(:base, ErrorMessages::Clean.call(e.message))
    end

    respond_to do |format|
      if @article
        format.json { render json: @article.errors, status: :unprocessable_entity }
      else
        format.json do
          front_matter = parsed.front_matter.to_h
          if front_matter["tags"]
            tags = Article.new.tag_list.add(front_matter["tags"], parser: ActsAsTaggableOn::TagParser)
          end
          if front_matter["cover_image"]
            cover_image = ApplicationController.helpers.cloud_cover_url(front_matter["cover_image"])
          end

          render json: {
            processed_html: processed_html,
            title: front_matter["title"],
            tags: tags,
            cover_image: cover_image
          }, status: :ok
        end
      end
    end
  end

  def create
    authorize Article
    @user = current_user
    article = Articles::Creator.call(@user, article_params_json)

    render json: if article.persisted?
                   { id: article.id, current_state_path: article.decorate.current_state_path }.to_json
                 else
                   article.errors.to_json
                 end
  end

  def update
    authorize @article
    @user = @article.user || current_user
    updated = Articles::Updater.call(@user, @article, article_params_json)

    respond_to do |format|
      format.html do
        # TODO: JSON should probably not be returned in the format.html section
        if article_params_json[:archived] && @article.archived # just to get archived working
          render json: @article.to_json(only: [:id], methods: [:current_state_path])
          return
        end
        if params[:destination]
          redirect_to(Addressable::URI.parse(params[:destination]).path)
          return
        end
        if params[:article][:video_thumbnail_url]
          redirect_to("#{@article.path}/edit")
          return
        end
        render json: { status: 200 }
      end

      format.json do
        render json: if updated.success
                       @article.to_json(only: [:id], methods: [:current_state_path])
                     else
                       @article.errors.to_json
                     end
      end
    end
  end

  def delete_confirm
    @article = Article.find_by(slug: params[:slug])
    not_found unless @article
    authorize @article
  end

  def destroy
    authorize @article
    Articles::Destroyer.call(@article)
    respond_to do |format|
      format.html { redirect_to "/dashboard", notice: I18n.t("articles_controller.deleted") }
      format.json { head :no_content }
    end
  end

  def stats
    authorize @article
    @organization_id = @article.organization_id
  end

  def admin_unpublish
    authorize @article

    result = Articles::Unpublish.call(current_user, @article)

    if result.success
      render json: { message: "success", path: @article.current_state_path }, status: :ok
    else
      render json: { message: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def admin_featured_toggle
    authorize @article

    @article.featured = params.dig(:article, :featured).to_i == 1

    if @article.save
      render json: { message: "success", path: @article.current_state_path }, status: :ok
    else
      render json: { message: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def discussion_lock_confirm
    # This allows admins to also use this action vs searching only in the current_user.articles scope
    @article = Article.find_by(slug: params[:slug])
    not_found unless @article
    authorize @article

    @discussion_lock = DiscussionLock.new
  end

  def discussion_unlock_confirm
    # This allows admins to also use this action vs searching only in the current_user.articles scope
    @article = Article.find_by(slug: params[:slug])
    not_found unless @article
    authorize @article

    @discussion_lock = @article.discussion_lock
  end

  private

  def base_editor_assignments
    @user = current_user
    @version = @user.setting.editor_version if @user
    @organizations = @user&.organizations
    @tag = Tag.find_by(name: params[:template])
    @prefill = params[:prefill].to_s.gsub("\\n ", "\n").gsub("\\n", "\n")
    @user_approved_liquid_tags = Users::ApprovedLiquidTags.call(@user)
  end

  def handle_user_or_organization_feed
    if (@user = User.find_by(username: params[:username]))
      Honeycomb.add_field("articles_route", "user")
      @articles = @articles.where(user_id: @user.id)
    elsif (@user = Organization.find_by(slug: params[:username]))
      Honeycomb.add_field("articles_route", "org")
      @articles = @articles.where(organization_id: @user.id).includes(:user)
    end
  end

  def handle_tag_feed
    tag_name = Tag.aliased_name(params[:tag])
    return unless tag_name

    @tag = Tag.find_by(name: tag_name)
    @articles = @articles.cached_tagged_with(tag_name)
  end

  def set_article
    owner = User.find_by(username: params[:username]) || Organization.find_by(slug: params[:username])
    found_article = if params[:slug] && owner
                      owner.articles.find_by(slug: params[:slug])
                    else
                      Article.includes(:user).find(params[:id])
                    end
    @article = found_article || not_found
    Honeycomb.add_field("article_id", @article.id)
  end

  # TODO: refactor all of this update logic into the Articles::Updater possibly,
  # ideally there should only be one place to handle the update logic
  def article_params_json
    return @article_params_json if @article_params_json

    params.require(:article) # to trigger the correct exception in case `:article` is missing

    params["article"].transform_keys!(&:underscore)

    allowed_params = if params["article"]["version"] == "v1"
                       %i[body_markdown]
                     else
                       %i[
                         title body_markdown main_image published description video_thumbnail_url
                         tag_list canonical_url series collection_id archived published_at timezone
                         published_at_date published_at_time
                       ]
                     end

    # NOTE: the organization logic is still a little counter intuitive but this should
    # fix the bug <https://github.com/forem/forem/issues/2871>
    if params["article"]["user_id"] && org_admin_user_change_privilege
      allowed_params << :user_id
    elsif params["article"]["organization_id"] && allowed_to_change_org_id?
      # change the organization of the article only if explicitly asked to do so
      allowed_params << :organization_id
    end

    time_zone_str = params["article"].delete("timezone")

    time = params["article"].delete("published_at_time")
    date = params["article"].delete("published_at_date")

    if date.present?
      time_zone = Time.find_zone(time_zone_str)
      time_zone ||= Time.find_zone("UTC")
      params["article"]["published_at"] = time_zone.parse("#{date} #{time}")
    elsif params["article"]["version"] != "v1"
      params["article"]["published_at"] = nil
    end

    @article_params_json = params.require(:article).permit(allowed_params)
  end

  def allowed_to_change_org_id?
    potential_user = @article&.user || current_user
    potential_org_id = params["article"]["organization_id"].presence || @article&.organization_id
    OrganizationMembership.exists?(user: potential_user, organization_id: potential_org_id) ||
      current_user.any_admin?
  end

  def org_admin_user_change_privilege
    params[:article][:user_id] &&
      # if current_user is an org admin of the article's org
      current_user.org_admin?(@article.organization_id) &&
      # and if the author being changed to belongs to the article's org
      OrganizationMembership.exists?(user_id: params[:article][:user_id], organization_id: @article.organization_id)
  end
end
