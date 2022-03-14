module Admin
  class ExtensionsController < Admin::ApplicationController
    layout "admin"

    EXTENSIONS = [
      Extension.new(
        "Listings",
        "Once turned on, Listings can be accessed via /listings and members will be able to add listings." \
        "Learn more about Listings <a href='https://admin.forem.com/docs/advanced-customization/listings'>here</a>.",
        :listing_feature,
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
