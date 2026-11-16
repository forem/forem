class UserEmbedPagesController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  before_action :require_embed_pages_access!
  before_action :set_page, only: %i[edit update destroy]

  def index
    @embed_pages = current_user.ordered_embed_pages
  end

  def new
    @page = current_user.pages.build(template: Page::EMBED_HTML_TEMPLATE)
  end

  def edit; end

  def create
    build_embed_page
    current_user.rate_limiter.consume!(:embed_page_creation)

    if @page.errors.none? && @page.save
      flash[:success] = I18n.t("views.dashboard.embed_pages.created")
      redirect_to dashboard_embed_pages_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue RateLimitChecker::LimitReached => e
    @page.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  def update
    assign_embed_page_updates
    current_user.rate_limiter.consume!(:embed_page_update)

    if @page.errors.none? && @page.save
      flash[:success] = I18n.t("views.dashboard.embed_pages.updated")
      redirect_to dashboard_embed_pages_path
    else
      render :edit, status: :unprocessable_entity
    end
  rescue RateLimitChecker::LimitReached => e
    @page.errors.add(:base, e.message)
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @page.destroy!
    flash[:success] = I18n.t("views.dashboard.embed_pages.deleted")
    redirect_to dashboard_embed_pages_path
  end

  private

  def require_embed_pages_access!
    not_found unless current_user.embed_pages_enabled?
    not_authorized unless current_user.registered? && !current_user.actively_spam_or_suspended?
  end

  def set_page
    @page = current_user.pages.embed_html.find(params[:id])
  end

  def build_embed_page
    @page = current_user.pages.build(embed_page_params)
    @page.template = Page::EMBED_HTML_TEMPLATE
    @page.position = 0
    @page.description = default_page_description if @page.description.blank?

    suffix = normalized_slug_suffix
    if suffix.blank?
      @page.errors.add(:slug, I18n.t("models.page.slug_blank"))
      return
    end

    @page.slug = "#{current_user.username}/embed/#{suffix}"
  end

  def assign_embed_page_updates
    @page.assign_attributes(embed_page_params)
    @page.description = default_page_description if @page.description.blank?

    suffix = normalized_slug_suffix
    if suffix.blank?
      @page.errors.add(:slug, I18n.t("models.page.slug_blank"))
      return
    end

    @page.slug = "#{current_user.username}/embed/#{suffix}"
  end

  def default_page_description
    current_user.profile&.summary.presence || current_user.name
  end

  def normalized_slug_suffix
    params.dig(:page, :slug_suffix)
      .to_s
      .strip
      .downcase
      .gsub(/[^a-z0-9\-]/, "-")
      .squeeze("-")
      .gsub(/\A-+|-+\z/, "")
  end

  def embed_page_params
    params.require(:page).permit(:title, :body_html, :description)
  end
end
