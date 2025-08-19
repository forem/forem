class SubforemsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  before_action :authenticate_user!, only: %i[edit update]
  before_action :set_subforem, only: %i[edit update]
  before_action :authorize_subforem, only: %i[edit update]

  def index
    @subforems = Subforem.where(discoverable: true, root: false).order(score: :desc)
  end

  def edit
    @subforem_moderators = User.with_role(:subforem_moderator, @subforem).select(:id, :username)
  end

  def update
    if current_user.any_admin?
      # Admins can update all fields
      if @subforem.update(admin_params)
        update_community_settings
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
        flash[:success] = "Subforem updated successfully!"
        redirect_to subforems_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :edit
      end
    elsif @subforem.update(moderator_params)
      # Regular subforem moderators can only update limited fields
      update_community_settings
      flash[:success] = "Subforem updated successfully!"
      redirect_to subforems_path
    else
      flash.now[:error] = @subforem.errors_as_sentence
      render :edit
    end
  end

  private

  def set_subforem
    @subforem = Subforem.find(params[:id])
  end

  def authorize_subforem
    authorize @subforem
  end

  def admin_params
    params.require(:subforem).permit(:domain, :discoverable, :root, :name, :logo_url, :bg_image_url)
  end

  def super_moderator_params
    params.require(:subforem).permit(:logo_url, :bg_image_url)
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

  def render_forbidden
    respond_to do |format|
      format.html { head :forbidden }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end
end
