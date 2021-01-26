module Admin
  class DataUpdateScriptsController < Admin::ApplicationController
    layout "admin"

    def index
      @data_update_scripts = DataUpdateScript.order(run_at: :desc)
    end

    def force_run
      response = DataUpdateScript.force_run(params[:id])

      render json: { response: response }
    end
  end
end
