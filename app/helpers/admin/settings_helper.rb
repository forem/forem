module Admin
  module SettingsHelper
    def billboard_enabled_countries_for_editing
      ::Settings::General.billboard_enabled_countries.to_json
    end

    def billboard_all_countries_for_editing
      ISO3166::Country.all.to_h { |country| [country.alpha2, country.common_name] }
    end
  end
end
