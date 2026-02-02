class SubforemsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  before_action :authenticate_user!, only: %i[edit update add_tag remove_tag create_navigation_link update_navigation_link destroy_navigation_link new_page create_page edit_page update_page destroy_page]
  before_action :set_subforem, only: %i[edit update add_tag remove_tag create_navigation_link update_navigation_link destroy_navigation_link new_page create_page edit_page update_page destroy_page]
  before_action :authorize_subforem, only: %i[edit update add_tag remove_tag]
  before_action :authorize_navigation_link_action, only: %i[create_navigation_link update_navigation_link destroy_navigation_link]
  before_action :authorize_page_action, only: %i[new_page create_page edit_page update_page destroy_page]
  after_action :bust_navigation_links_cache, only: %i[create_navigation_link update_navigation_link destroy_navigation_link]
  after_action :bust_content_change_caches, only: %i[create_navigation_link update_navigation_link destroy_navigation_link]

  def index
    @subforems = Subforem.where(discoverable: true, root: false).order(score: :desc)
  end

  def new
    @survey = Survey.find_by(id: ENV["SUBFOREM_SURVEY_ID"].to_i) if ENV["SUBFOREM_SURVEY_ID"].present?
  end

  def edit
    @subforem_moderators = User.with_role(:subforem_moderator, @subforem).select(:id, :username)

    # Get supported tags for this subforem
    @supported_tags = @subforem.tag_relationships.includes(:tag).where(supported: true).map(&:tag)

    # Get top 25 tags not supported by this subforem
    supported_tag_ids = @subforem.tag_relationships.where(supported: true).pluck(:tag_id)
    @unsupported_tags = Tag.where(supported: true)
      .where.not(id: supported_tag_ids)
      .order(taggings_count: :desc)
      .limit(25)

    # Get pages for this subforem
    @pages = Page.where(subforem_id: @subforem.id).order(:title)

    # Get navigation links for this subforem
    @navigation_links = NavigationLink.where(subforem_id: @subforem.id).ordered
  end

  def update
    if current_user.any_admin?
      # Admins can update all fields
      if @subforem.update(admin_params)
        update_community_settings
        update_user_experience_settings
        update_subforem_images
        Settings::General.set_admin_action_taken_at(Time.current, subforem_id: @subforem.id)
        flash[:success] = I18n.t("views.subforems.edit.messages.updated")
        redirect_to manage_subforem_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :edit
      end
    elsif current_user.super_moderator?
      # Super moderators can update most fields except domain, name, and discoverable
      if @subforem.update(super_moderator_params)
        update_community_settings
        update_user_experience_settings
        update_subforem_images
        Settings::General.admin_action_taken_at = Time.current
        flash[:success] = I18n.t("views.subforems.edit.messages.updated")
        redirect_to manage_subforem_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :edit
      end
    elsif @subforem.update(moderator_params)
      # Regular subforem moderators can only update limited fields
      update_community_settings
      update_user_experience_settings
      update_subforem_images
      Settings::General.admin_action_taken_at = Time.current
      flash[:success] = I18n.t("views.subforems.edit.messages.updated")
      redirect_to manage_subforem_path
    else
      flash.now[:error] = @subforem.errors_as_sentence
      render :edit
    end
  end

  def add_tag
    tag = Tag.find(params[:tag_id])
    tag.update(supported: true) unless tag.supported?

    # Check if relationship already exists
    existing_relationship = @subforem.tag_relationships.find_by(tag: tag)

    if existing_relationship
      if existing_relationship.supported?
        render json: { success: false, message: "Tag is already supported" }, status: :unprocessable_entity
      else
        existing_relationship.update!(supported: true)
        render json: { success: true, message: "Tag added to supported tags" }
      end
    else
      @subforem.tag_relationships.create!(tag: tag, supported: true)
      render json: { success: true, message: "Tag added to supported tags" }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "Tag not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def remove_tag
    tag = Tag.find(params[:tag_id])
    
    # Find and remove the relationship
    relationship = @subforem.tag_relationships.find_by(tag: tag)
    
    if relationship
      relationship.destroy!
      render json: { success: true, message: "Tag removed from supported tags" }
    else
      render json: { success: false, message: "Tag is not supported by this subforem" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "Tag not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def create_navigation_link
    navigation_link = NavigationLink.new(navigation_link_params.merge(subforem_id: @subforem.id))
    
    if navigation_link.save
      flash[:success] = I18n.t("views.subforems.edit.navigation_links.messages.created")
      redirect_to manage_subforem_path
    else
      flash[:error] = navigation_link.errors_as_sentence
      redirect_to manage_subforem_path
    end
  end

  def update_navigation_link
    navigation_link = NavigationLink.find(params[:navigation_link_id])
    
    # Ensure the link belongs to this subforem
    unless navigation_link.subforem_id == @subforem.id
      flash[:error] = I18n.t("views.subforems.edit.navigation_links.messages.not_found")
      redirect_to manage_subforem_path
      return
    end
    
    if navigation_link.update(navigation_link_params)
      flash[:success] = I18n.t("views.subforems.edit.navigation_links.messages.updated")
    else
      flash[:error] = navigation_link.errors_as_sentence
    end
    redirect_to manage_subforem_path
  end

  def destroy_navigation_link
    navigation_link = NavigationLink.find(params[:navigation_link_id])
    
    # Ensure the link belongs to this subforem
    unless navigation_link.subforem_id == @subforem.id
      flash[:error] = I18n.t("views.subforems.edit.navigation_links.messages.not_found")
      redirect_to manage_subforem_path
      return
    end
    
    if navigation_link.destroy
      flash[:success] = I18n.t("views.subforems.edit.navigation_links.messages.deleted")
    else
      flash[:error] = navigation_link.errors_as_sentence
    end
    redirect_to manage_subforem_path
  end

  def new_page
    @page = Page.new(subforem_id: @subforem.id)
  end

  def create_page
    @page = Page.new(page_params.merge(subforem_id: @subforem.id))
    
    # Force markdown-only pages, no top-level paths for subforem moderators
    @page.body_html = nil
    @page.body_json = nil
    @page.body_css = nil
    @page.template = "contained"
    @page.is_top_level_path = false
    
    if @page.save
      flash[:success] = I18n.t("views.subforems.pages.created")
      redirect_to @page.path
    else
      flash.now[:error] = @page.errors_as_sentence
      render :new_page
    end
  end

  def edit_page
    @page = Page.find(params[:page_id])
    
    # Ensure the page belongs to this subforem
    unless @page.subforem_id == @subforem.id
      flash[:error] = I18n.t("views.subforems.pages.not_found")
      redirect_to manage_subforem_path
      return
    end
  end

  def update_page
    @page = Page.find(params[:page_id])
    
    # Ensure the page belongs to this subforem
    unless @page.subforem_id == @subforem.id
      flash[:error] = I18n.t("views.subforems.pages.not_found")
      redirect_to manage_subforem_path
      return
    end
    
    # Determine allowed params based on page type and user role
    allowed_params = if @page.is_top_level_path
                       # For top-level pages, mods can update title, description, body_markdown, and social_image
                       # but cannot change slug, template, or is_top_level_path
                       page_params.slice(:title, :description, :body_markdown, :social_image)
                     else
                       # For subforem pages, allow full markdown editing
                       params_to_use = page_params
                       # Force markdown-only, no HTML/JSON/CSS for subforem moderators
                       params_to_use = params_to_use.except(:body_html, :body_json, :body_css)
                       params_to_use.merge(template: "contained", is_top_level_path: false)
                     end
    
    if @page.update(allowed_params)
      flash[:success] = I18n.t("views.subforems.pages.updated")
      redirect_to @page.path
    else
      flash.now[:error] = @page.errors_as_sentence
      render :edit_page
    end
  end

  def destroy_page
    @page = Page.find(params[:page_id])
    
    # Ensure the page belongs to this subforem and is not a top-level page
    unless @page.subforem_id == @subforem.id && !@page.is_top_level_path
      flash[:error] = I18n.t("views.subforems.pages.cannot_delete")
      redirect_to manage_subforem_path
      return
    end
    
    if @page.destroy
      flash[:success] = I18n.t("views.subforems.pages.deleted")
    else
      flash[:error] = @page.errors_as_sentence
    end
    redirect_to manage_subforem_path
  end

  private

  def set_subforem
    @subforem = Subforem.find(params[:id] || params[:subforem_id] || RequestStore.store[:subforem_id])
  end

  def authorize_subforem
    authorize @subforem
  end

  def authorize_navigation_link_action
    # Use the specific policy method based on the action
    case action_name
    when "create_navigation_link"
      authorize @subforem, :create_navigation_link?
    when "update_navigation_link"
      authorize @subforem, :update_navigation_link?
    when "destroy_navigation_link"
      authorize @subforem, :destroy_navigation_link?
    end
  end

  def authorize_page_action
    # Use the specific policy method based on the action
    case action_name
    when "new_page", "create_page"
      authorize @subforem, :create_page?
    when "edit_page", "update_page"
      authorize @subforem, :update_page?
    when "destroy_page"
      authorize @subforem, :destroy_page?
    end
  end

  def navigation_link_params
    params.require(:navigation_link).permit(:name, :url, :icon, :image, :display_to, :position, :section)
  end

  def page_params
    params.require(:page).permit(:title, :slug, :description, :body_markdown, :social_image)
  end

  def admin_params
    params.require(:subforem).permit(:domain, :discoverable, :root, :name)
  end

  def super_moderator_params
    params.require(:subforem).permit
  end

  def moderator_params
    # Moderators can't update subforem fields directly, only through settings
    params.fetch(:subforem, {}).permit
  end

  def update_community_settings
    return unless params[:community_name].present? || params[:community_description].present? || 
                  params[:tagline].present? || params[:member_label].present? || 
                  params[:internal_content_description_spec].present? || params[:sidebar_tags].present?

    # Only admins can update community_name
    if params[:community_name].present? && current_user.any_admin?
      Settings::Community.set_community_name(params[:community_name], subforem_id: @subforem.id)
    end
    
    if params[:community_description].present?
      Settings::Community.set_community_description(params[:community_description],
                                                    subforem_id: @subforem.id)
    end
    
    if params[:tagline].present?
      Settings::Community.set_tagline(params[:tagline], subforem_id: @subforem.id)
    end
    
    if params[:member_label].present?
      Settings::Community.set_member_label(params[:member_label], subforem_id: @subforem.id)
    end
    
    if params[:internal_content_description_spec].present?
      Settings::RateLimit.set_internal_content_description_spec(params[:internal_content_description_spec],
                                                                subforem_id: @subforem.id)
    end

    return unless params[:sidebar_tags].present?

    # Parse and set sidebar tags
    sidebar_tags = params[:sidebar_tags].to_s.downcase.delete(" ").split(",").reject(&:blank?)
    Settings::General.set_sidebar_tags(sidebar_tags, subforem_id: @subforem.id)
    # Create tags if they don't exist
    Tag.find_or_create_all_with_like_by_name(sidebar_tags)
  end

  def update_user_experience_settings
    return unless params[:feed_style].present? || params[:feed_lookback_days].present? || 
                  params[:primary_brand_color_hex].present? || params[:cover_image_aesthetic_instructions].present?

    if params[:feed_style].present?
      Settings::UserExperience.set_feed_style(params[:feed_style], subforem_id: @subforem.id)
    end
    
    if params[:feed_lookback_days].present?
      Settings::UserExperience.set_feed_lookback_days(params[:feed_lookback_days].to_i, subforem_id: @subforem.id)
    end
    
    if params[:primary_brand_color_hex].present?
      Settings::UserExperience.set_primary_brand_color_hex(params[:primary_brand_color_hex], subforem_id: @subforem.id)
    end
    
    if params.key?(:cover_image_aesthetic_instructions)
      Settings::UserExperience.set_cover_image_aesthetic_instructions(params[:cover_image_aesthetic_instructions], subforem_id: @subforem.id)
    end
  end

  def update_subforem_images
    # Only admins and super moderators can upload images
    return unless current_user.any_admin? || current_user.super_moderator?

    # Handle main logo upload
    if params[:subforem][:main_logo].present?
      uploader = upload_subforem_image(params[:subforem][:main_logo], "main_logo")
      Settings::General.set_logo_png(uploader.main_logo.url, subforem_id: @subforem.id)
    end

    # Handle nav logo upload
    if params[:subforem][:nav_logo].present?
      uploader = upload_subforem_image(params[:subforem][:nav_logo], "nav_logo")
      Settings::General.set_resized_logo(uploader.nav_logo.url, subforem_id: @subforem.id)
    end

    # Handle social card upload
    return unless params[:subforem][:social_card].present?

    uploader = upload_subforem_image(params[:subforem][:social_card], "social_card")
    Settings::General.set_main_social_image(uploader.social_card.url, subforem_id: @subforem.id)
  end

  def upload_subforem_image(image, image_type)
    SubforemImageUploader.new.tap do |uploader|
      uploader.set_image_type(image_type)
      uploader.store!(image)
    end
  end

  def bust_navigation_links_cache
    # Bust the cache for navigation links
    Rails.cache.delete("navigation_links")
    Rails.cache.delete("navigation_links-true-#{@subforem.id}")
    Rails.cache.delete("navigation_links-false-#{@subforem.id}")
    EdgeCache::Bust.call("/async_info/navigation_links")
  end

  def render_forbidden
    respond_to do |format|
      format.html { head :forbidden }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end
end
