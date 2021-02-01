module Admin
  class DataUpdateScriptsController < Admin::ApplicationController
    layout "admin"

    def index
      @data_update_scripts = DataUpdateScript.all
    end

    private

    def authorize_admin
      authorize DataUpdateScript, :access?, policy_class: InternalPolicy
    end
  end
end
