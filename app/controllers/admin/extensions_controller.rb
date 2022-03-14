module Admin
  class ExtensionsController < Admin::ApplicationController
    layout "admin"

    EXTENSIONS = [
      Extension.new(
        "Listings",
        "A description of the listing feature <br> With some more sub text",
        :listing_feature,
      ),
      Extension.new(
        "Admin Member View",
        "A description of the listing feature <br> With some more sub text",
        :admin_member_view,
      ),
    ].freeze

    def index
      @extensions = EXTENSIONS
    end

    def toggle
      EXTENSIONS.each do |extension|
        if params[extension.feature_flag_name].to_i == 1
          extension.enable
        else
          extension.disable
        end
      end
      flash[:success] = "Feature Flags have been updated"
      redirect_to admin_extensions_path
    end
  end
end
