module Admin
  class DataUpdateScriptsController < Admin::ApplicationController
    layout "admin"

    def index
      @data_update_scripts = DataUpdateScript.order(run_at: :desc)
    end

    def show
      response = DataUpdateScript.find(params[:id])
      render json: { response: response }
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "#{e.class}: #{e.message}" }, status: :not_found
    end

    def force_run
      DataUpdateWorker.perform_async(params[:id])
    end

    private

    def authorize_admin
      authorize DataUpdateScript, :access?, policy_class: InternalPolicy
    end
  end
end
