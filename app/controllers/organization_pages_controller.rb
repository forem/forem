class OrganizationPagesController < ApplicationController
  include OrganizationAdminScoped
  before_action :set_page, only: %i[edit update destroy]
  before_action :check_pages_feature

  def index
    @pages = @organization.pages.order(:created_at)
  end

  def new
    @page = @organization.pages.build(template: "full_within_layout")
  end

  def create
    is_first_page = !@organization.pages.exists?
    @page = @organization.pages.build(page_params)
    @page.template = "full_within_layout"
    
    if is_first_page
      @page.slug = "#{@organization.slug}/readme"
      @page.title = @organization.name if @page.title.blank?
    elsif params.dig(:page, :slug_suffix).present?
      suffix = params[:page][:slug_suffix].to_s.strip.downcase.gsub(/[^a-z0-9\-]/, "-").gsub(/-+/, "-").strip
      @page.slug = "#{@organization.slug}/#{suffix}"
    end

    @page.description = @organization.summary.presence || @organization.name if @page.description.blank?

    if @page.save
      flash[:settings_notice] = I18n.t("views.organization_settings.pages.created")
      redirect_to organization_pages_path(@organization.slug)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @page.assign_attributes(page_params)
    
    if @page.slug.end_with?("/readme")
      @page.slug = "#{@organization.slug}/readme"
    elsif params.dig(:page, :slug_suffix).present?
      suffix = params[:page][:slug_suffix].to_s.strip.downcase.gsub(/[^a-z0-9\-]/, "-").gsub(/-+/, "-").strip
      @page.slug = "#{@organization.slug}/#{suffix}"
    end

    if @page.save
      flash[:settings_notice] = I18n.t("views.organization_settings.pages.updated")
      redirect_to organization_pages_path(@organization.slug)
    else
      render :edit
    end
  end

  def destroy
    @page.destroy
    flash[:settings_notice] = I18n.t("views.organization_settings.pages.deleted")
    redirect_to organization_pages_path(@organization.slug)
  end

  def preview
    renderer = ContentRenderer.new(params[:body_markdown].to_s, source: @organization, user: current_user)
    result = renderer.process
    render json: { processed_html: result.processed_html }
  rescue ContentRenderer::ContentParsingError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_page
    @page = @organization.pages.find(params[:id])
  end

  def check_pages_feature
    not_found unless FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[@organization])
  end

  def page_params
    params.require(:page).permit(:title, :body_markdown, :description)
  end
end
