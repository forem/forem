module Admin
  class SubforemsController < Admin::ApplicationController
    layout "admin"

    SUBFOREM_ALLOWED_PARAMS = %i[
      domain discoverable root name brain_dump logo_url bg_image_url
    ].freeze

    def index
      @subforems = Subforem.order(created_at: :desc)
    end

    def new
      @subforem = Subforem.new
    end

    def edit
      @subforem = Subforem.find(params[:id])
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
      @subforem = Subforem.find(params[:id])
      if @subforem.update(subforem_params)
        flash[:success] = I18n.t("admin.subforems_controller.updated")
        redirect_to admin_subforems_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :edit
      end
    end

    private

    def subforem_params
      params.require(:subforem).permit(SUBFOREM_ALLOWED_PARAMS)
    end

    def create_from_scratch_params_present?
      subforem_params[:domain].present? &&
        subforem_params[:brain_dump].present? &&
        subforem_params[:name].present? &&
        subforem_params[:logo_url].present?
    end
  end
end
