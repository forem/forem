module Admin
  class FeatureFlagsController < Admin::ApplicationController
    layout "admin"

    FEATURE_FLAGS = [
      {
        name: "Listings",
        description: "A description of the listing feature <br> With some more sub text",
        feature_flag: :listing_feature

      },
    ].freeze

    def index
      @feature_flags = FEATURE_FLAGS
    end

    def toggle_flags
      FEATURE_FLAGS.each do |flag|
        if params[flag[:feature_flag]].to_i == 1
          unless FeatureFlag.exist?(flag[:feature_flag])
            FeatureFlag.add(flag[:feature_flag])
          end
          FeatureFlag.enable(flag[:feature_flag])
        else
          FeatureFlag.disable(flag[:feature_flag])
        end
      end
      redirect_to admin_feature_flags_path
    end
  end
end
