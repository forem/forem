module Admin
  class SubforemsController < Admin::ApplicationController
    layout "admin"

    SUBFOREM_ALLOWED_PARAMS = %i[
      domain discoverable root name brain_dump logo_url bg_image_url default_locale
    ].freeze

    MODERATOR_ALLOWED_PARAMS = %i[
      discoverable
    ].freeze

    COMMUNITY_SETTINGS_PARAMS = %i[
      community_description tagline member_label
    ].freeze

    before_action :set_subforem, only: %i[show edit update]
    before_action :authorize_subforem, only: %i[show edit update]

    def index
      @subforems = Subforem.order(created_at: :desc)
    end

    def show
      @subforem_moderators = User.with_role(:subforem_moderator, @subforem).select(:id, :username)
    end

    def new
      @subforem = Subforem.new
    end

    def edit
      @subforem_moderators = User.with_role(:subforem_moderator, @subforem).select(:id, :username)
    end

    def create
      @subforem = Subforem.new(subforem_params)

      # Check if we have the required parameters for create_from_scratch!
      if create_from_scratch_params_present?
        begin
          @subforem = Subforem.create_from_scratch!(
            domain: subforem_params[:domain],
            brain_dump: subforem_params[:brain_dump],
            name: subforem_params[:name],
            logo_url: subforem_params[:logo_url],
            bg_image_url: subforem_params[:bg_image_url],
            default_locale: subforem_params[:default_locale] || 'en',
          )
          flash[:success] = I18n.t("admin.subforems_controller.created_with_ai")
          redirect_to admin_subforems_path
        rescue StandardError => e
          flash.now[:error] = "Failed to create subforem: #{e.message}"
          render :new
        end
      elsif @subforem.save
        # Fall back to regular creation
        flash[:success] = I18n.t("admin.subforems_controller.created")
        redirect_to admin_subforems_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :new
      end
    end

    def update
      if current_user.any_admin?
        # Admins can update all fields
        if @subforem.update(subforem_params)
          update_community_settings
          flash[:success] = I18n.t("admin.subforems_controller.updated")
          redirect_to admin_subforems_path
        else
          flash.now[:error] = @subforem.errors_as_sentence
          render :edit
        end
      elsif @subforem.update(moderator_params)
        # Moderators can only update limited fields
        update_community_settings
        flash[:success] = I18n.t("admin.subforems_controller.updated")
        redirect_to admin_subforems_path
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

    def subforem_params
      params.require(:subforem).permit(SUBFOREM_ALLOWED_PARAMS)
    end

    def moderator_params
      params.require(:subforem).permit(MODERATOR_ALLOWED_PARAMS)
    end

    def create_from_scratch_params_present?
      subforem_params[:domain].present? &&
        subforem_params[:brain_dump].present? &&
        subforem_params[:name].present? &&
        subforem_params[:logo_url].present?
    end

    def update_community_settings
      return unless params[:community_description].present? || params[:tagline].present? || params[:member_label].present?

      if params[:community_description].present?
        Settings::Community.set_community_description(params[:community_description],
                                                      subforem_id: @subforem.id)
      end
      Settings::Community.set_tagline(params[:tagline], subforem_id: @subforem.id) if params[:tagline].present?
      return unless params[:member_label].present?

      Settings::Community.set_member_label(params[:member_label],
                                           subforem_id: @subforem.id)
    end
  end
end
