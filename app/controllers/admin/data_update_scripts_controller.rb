module Admin
  class DataUpdateScriptsController < Admin::ApplicationController
    layout "admin"

    def index
      @data_update_scripts = DataUpdateScript.order(run_at: :desc)
    end
  end
end
