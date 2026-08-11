class OrganizationPagesController < ApplicationController
  include OrganizationAdminScoped
  before_action :check_pages_feature
  before_action :set_page, only: %i[edit update destroy reorder]
  before_action :validate_reorder_direction, only: :reorder

  def index
    @pages = @organization.ordered_pages
    @showcase_page = @pages.first
  end

  def new
    @page = @organization.pages.build(template: "full_within_layout")
  end

  def create
    is_first_page = !@organization.pages.exists?
    @page = @organization.pages.build(page_params)
    @page.template = "full_within_layout"
    @page.position = (@organization.pages.maximum(:position) || -1) + 1
    
    if is_first_page
      @page.slug = "#{@organization.slug}/readme"
      @page.title = @organization.name if @page.title.blank?
    else
      suffix = params.dig(:page, :slug_suffix).to_s.strip.downcase.gsub(/[^a-z0-9\-]/, "-").gsub(/-+/, "-").gsub(/\A-+|-+\z/, "")
      if suffix.blank?
        @page.errors.add(:slug, "suffix is required and must contain alphanumeric characters or hyphens")
        return render :new, status: :unprocessable_entity
      end
      @page.slug = "#{@organization.slug}/#{suffix}"
    end

    @page.description = @organization.summary.presence || @organization.name if @page.description.blank?

    if @page.save
      flash[:settings_notice] = I18n.t("views.organization_settings.pages.created")
      redirect_to organization_pages_path(@organization.slug)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @page.assign_attributes(page_params)
    
    if @page.slug.end_with?("/readme")
      @page.slug = "#{@organization.slug}/readme"
    else
      suffix = params.dig(:page, :slug_suffix).to_s.strip.downcase.gsub(/[^a-z0-9\-]/, "-").gsub(/-+/, "-").gsub(/\A-+|-+\z/, "")
      if suffix.blank?
        @page.errors.add(:slug, "suffix is required and must contain alphanumeric characters or hyphens")
        return render :edit, status: :unprocessable_entity
      end
      @page.slug = "#{@organization.slug}/#{suffix}"
    end

    if @page.save
      Pages::BustCacheWorker.perform_async(@page.slug)
      flash[:settings_notice] = I18n.t("views.organization_settings.pages.updated")
      redirect_to organization_pages_path(@organization.slug)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page.destroy
    flash[:settings_notice] = I18n.t("views.organization_settings.pages.deleted")
    redirect_to organization_pages_path(@organization.slug)
  end

  def reorder
    if reorder_page(params[:direction].to_s)
      Pages::BustCacheWorker.perform_async(@page.slug, @organization.id)
      flash[:settings_notice] = I18n.t("views.organization_settings.pages.reordered")
    end

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

  def showcase_page?(page)
    page == @organization.main_page
  end

  def reorder_page(direction)
    return false if showcase_page?(@page)

    Page.transaction do
      pages = ordered_custom_pages
      current_index = pages.index { |page| page.id == @page.id }
      adjacent_index = adjacent_index_for(current_index, direction)
      next false unless adjacent_index&.between?(0, pages.length - 1)

      normalize_positions(pages)
      swap_positions(pages, current_index, adjacent_index)
      true
    end
  end

  def ordered_custom_pages
    @organization.ordered_pages.where.not(id: @organization.main_page.id).lock.to_a
  end

  def adjacent_index_for(current_index, direction)
    current_index && (current_index + (direction == "up" ? -1 : 1))
  end

  def normalize_positions(pages)
    pages.each_with_index do |page, index|
      update_position(page, index + 1) unless page.position == index + 1
    end
  end

  def swap_positions(pages, current_index, adjacent_index)
    update_position(pages.fetch(current_index), adjacent_index + 1)
    update_position(pages.fetch(adjacent_index), current_index + 1)
  end

  def update_position(page, position)
    # Ordering does not affect page validity or rendered Markdown, so avoid recompiling page content.
    page.update_columns(position: position, updated_at: Time.current)
  end

  def validate_reorder_direction
    head :unprocessable_entity unless %w[up down].include?(params[:direction].to_s)
  end
end
