module Admin
  class DataUpdateScriptsController < Admin::ApplicationController
    layout "admin"

    def index
      @data_update_scripts = DataUpdateScript.order(run_at: :desc)
    end

    def run_data_update_scripts
      data_update_script_id = params[:id]
      response = DataUpdateScript.force_run(data_update_script_id)

      render json: { response: response }
    end
  end
end
