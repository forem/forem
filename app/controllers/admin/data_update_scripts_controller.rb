module Admin
  class DataUpdateScriptsController < Admin::ApplicationController
    layout "admin"

    def index
      @data_update_scripts = DataUpdateScript.all
    end
  end
end
