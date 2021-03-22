class ArticlesController < ApplicationController
  include ApplicationHelper

  before_action :authenticate_user!, except: %i[feed new]
  before_action :set_article, only: %i[edit manage update destroy stats admin_unpublish]
  before_action :raise_suspended, only: %i[new create update]
  before_action :set_cache_control_headers, only: %i[feed]
  after_action :verify_authorized

  FEED_ALLOWED_TAGS = %w[
    a b blockquote br center cite code col colgroup dd del div dl dt em em h1 h2
    h3 h4 h5 h6 i iframe img li ol p pre q small span strong sup table tbody td
    tfoot th thead time tr u ul
  ].freeze

  FEED_ALLOWED_ATTRIBUTES = %w[
    alt class colspan data-conversation data-lang em height href id ref rel
    rowspan size span src start strong title value width
  ].freeze

  def feed
    skip_authorization

    @articles = Article.feed.order(published_at: :desc).page(params[:page].to_i).per(12)
    @articles = if params[:username]
                  handle_user_or_organization_feed
                elsif params[:tag]
                  handle_tag_feed
                elsif request.path == latest_feed_path
                  @articles.where("score > ?", Articles::Feeds::LargeForemExperimental::MINIMUM_SCORE_LATEST_FEED)
                    .includes(:user)
                else
                  @articles.where(featured: true).includes(:user)
                end

    not_found unless @articles&.any?

    set_surrogate_key_header "feed"
    set_cache_control_headers(10.minutes.to_i, stale_while_revalidate: 30, stale_if_error: 1.day.to_i)

    render layout: false, locals: {
      articles: @articles,
      user: @user,
      tag: @tag,
      allowed_tags: FEED_ALLOWED_TAGS,
      allowed_attributes: FEED_ALLOWED_ATTRIBUTES
    }
  end

  def new
    base_editor_assigments

    @article, needs_authorization = Articles::Builder.call(@user, @tag, @prefill)

    if needs_authorization
      authorize(Article)
    else
      skip_authorization
      store_location_for(:user, request.path)
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
    @user = @article.user
    @rating_vote = RatingVote.where(article_id: @article.id, user_id: @user.id).first
    @buffer_updates = BufferUpdate.where(composer_user_id: @user.id, article_id: @article.id)
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
      @article.errors[:base] << ErrorMessages::Clean.call(e.message)
    end

    respond_to do |format|
      if @article
        format.json { render json: @article.errors, status: :unprocessable_entity }
      else
        format.json do
          render json: {
            processed_html: processed_html,
            title: parsed["title"],
            tags: (Article.new.tag_list.add(parsed["tags"], parser: ActsAsTaggableOn::TagParser) if parsed["tags"]),
            cover_image: (ApplicationController.helpers.cloud_cover_url(parsed["cover_image"]) if parsed["cover_image"])
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
          redirect_to(URI.parse(params[:destination]).path)
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
    @article = current_user.articles.find_by(slug: params[:slug])
    not_found unless @article
    authorize @article
  end

  def destroy
    authorize @article
    Articles::Destroyer.call(@article)
    respond_to do |format|
      format.html { redirect_to "/dashboard", notice: "Article was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def stats
    authorize current_user, :pro_user?
    authorize @article
    @organization_id = @article.organization_id
  end

  def admin_unpublish
    authorize @article
    if @article.has_frontmatter?
      @article.body_markdown.sub!(/\npublished:\s*true\s*\n/, "\npublished: false\n")
    else
      @article.published = false
    end

    if @article.save
      render json: { message: "success", path: @article.current_state_path }, status: :ok
    else
      render json: { message: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def base_editor_assigments
    @user = current_user
    @version = @user.editor_version if @user
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
    @tag = Tag.aliased_name(params[:tag])
    return unless @tag

    @articles = @articles.cached_tagged_with(@tag)
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
    params.require(:article) # to trigger the correct exception in case `:article` is missing

    params["article"].transform_keys!(&:underscore)

    allowed_params = if params["article"]["version"] == "v1"
                       %i[body_markdown]
                     else
                       %i[
                         title body_markdown main_image published description video_thumbnail_url
                         tag_list canonical_url series collection_id archived
                       ]
                     end

    # NOTE: the organization logic is still a little counter intuitive but this should
    # fix the bug <https://github.com/thepracticaldev/dev.to/issues/2871>
    if params["article"]["user_id"] && org_admin_user_change_privilege
      allowed_params << :user_id
    elsif params["article"]["organization_id"] && allowed_to_change_org_id?
      # change the organization of the article only if explicitly asked to do so
      allowed_params << :organization_id
    end

    params.require(:article).permit(allowed_params)
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
