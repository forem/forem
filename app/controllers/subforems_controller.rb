class SubforemsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  before_action :authenticate_user!, only: %i[edit update add_tag]
  before_action :set_subforem, only: %i[edit update add_tag]
  before_action :authorize_subforem, only: %i[edit update add_tag]

  def index
    @subforems = Subforem.where(discoverable: true, root: false).order(score: :desc)
  end

  def new
    # Let's just not show the survey for now — still WIP
    # @survey = Survey.find(ENV["SUBFOREM_SURVEY_ID"].to_i) if ENV["SUBFOREM_SURVEY_ID"].present?
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
        update_subforem_images
        Settings::General.set_admin_action_taken_at(Time.current, subforem_id: @subforem.id)
        flash[:success] = "Subforem updated successfully!"
        redirect_to subforems_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :edit
      end
    elsif current_user.super_moderator?
      # Super moderators can update most fields except domain, name, and discoverable
      if @subforem.update(super_moderator_params)
        update_community_settings
        update_subforem_images
        Settings::General.admin_action_taken_at = Time.current
        flash[:success] = "Subforem updated successfully!"
        redirect_to subforems_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :edit
      end
    elsif @subforem.update(moderator_params)
      # Regular subforem moderators can only update limited fields
      update_community_settings
      update_subforem_images
      Settings::General.admin_action_taken_at = Time.current
      flash[:success] = "Subforem updated successfully!"
      redirect_to subforems_path
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

  private

  def set_subforem
    @subforem = Subforem.find(params[:id] || params[:subforem_id] || RequestStore.store[:subforem_id])
  end

  def authorize_subforem
    authorize @subforem
  end

  def admin_params
    params.require(:subforem).permit(:domain, :discoverable, :root, :name)
  end

  def super_moderator_params
    params.require(:subforem).permit
  end

  def moderator_params
    params.require(:subforem).permit(:discoverable)
  end

  def update_community_settings
    return unless params[:community_description].present? || params[:tagline].present? || params[:internal_content_description_spec].present?

    if params[:community_description].present?
      Settings::Community.set_community_description(params[:community_description],
                                                    subforem_id: @subforem.id)
    end
    Settings::Community.set_tagline(params[:tagline], subforem_id: @subforem.id) if params[:tagline].present?
    return unless params[:internal_content_description_spec].present?

    Settings::RateLimit.set_internal_content_description_spec(params[:internal_content_description_spec],
                                                              subforem_id: @subforem.id)
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

  def render_forbidden
    respond_to do |format|
      format.html { head :forbidden }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end
end
