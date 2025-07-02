module Admin
  class SubforemsController < Admin::ApplicationController
    layout "admin"
  
    SUBFOREM_ALLOWED_PARAMS = %i[
      domain discoverable root
    ].freeze

    def index
      @subforems = Subforem.order(created_at: :desc)
    end

    def new
      @subforem = Subforem.new
    end

    def create
      @subforem = Subforem.new(subforem_params)
      if @subforem.save
        flash[:success] = I18n.t("admin.subforems_controller.created")
        redirect_to admin_subforems_path
      else
        flash.now[:error] = @subforem.errors_as_sentence
        render :new
      end
    end

    def edit
      @subforem = Subforem.find(params[:id])
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
  end
end