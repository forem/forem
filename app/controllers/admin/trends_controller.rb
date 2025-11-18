module Admin
  class TrendsController < Admin::ApplicationController
    layout "admin"

    TREND_ALLOWED_PARAMS = %i[
      subforem_id short_title public_description full_content_description expiry_date
    ].freeze

    before_action :set_trend, only: %i[show edit update destroy]
    before_action :set_subforems, only: %i[index new edit]

    def index
      set_subforems
      @trends = Trend.includes(:subforem).order(created_at: :desc)
      @trends = @trends.where(subforem_id: params[:subforem_id]) if params[:subforem_id].present?
    end

    def show
    end

    def new
      @trend = Trend.new
      @trend.subforem_id = params[:subforem_id] if params[:subforem_id].present?
    end

    def edit
    end

    def create
      @trend = Trend.new(trend_params)

      if @trend.save
        flash[:success] = I18n.t("admin.trends_controller.created")
        redirect_to admin_trends_path
      else
        set_subforems
        flash.now[:error] = @trend.errors_as_sentence
        render :new
      end
    end

    def update
      if @trend.update(trend_params)
        flash[:success] = I18n.t("admin.trends_controller.updated")
        redirect_to admin_trends_path
      else
        set_subforems
        flash.now[:error] = @trend.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @trend.destroy
      flash[:success] = I18n.t("admin.trends_controller.deleted")
      redirect_to admin_trends_path
    end

    private

    def set_trend
      @trend = Trend.find(params[:id])
    end

    def set_subforems
      @subforems = Subforem.order(:domain)
    end

    def trend_params
      params.require(:trend).permit(TREND_ALLOWED_PARAMS)
    end
  end
end

