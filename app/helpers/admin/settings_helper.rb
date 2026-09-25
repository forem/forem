module Admin
  module SettingsHelper
    def billboard_enabled_countries_for_editing
      ::Settings::General.billboard_enabled_countries.to_json
    end

    def billboard_all_countries_for_editing
      ISO3166::Country.all.to_h { |country| [country.alpha2, country.common_name] }
    end

    # Select options for an AI function's model. Options whose API key is missing are
    # disabled (unless currently selected, so the admin can see what is stored).
    def ai_function_model_options(function, current)
      options = Ai::FunctionConfig.options_for(function)
      labeled = options.map do |option|
        label = Ai::FunctionConfig.option_label(option)
        unless Ai::FunctionConfig.option_available?(option)
          label = "#{label} (requires #{Ai::FunctionConfig.missing_key_for(option)})"
        end
        [label, option]
      end
      disabled = options.reject { |option| option == current || Ai::FunctionConfig.option_available?(option) }

      options_for_select(labeled, selected: current, disabled: disabled)
    end

    def new_user_status_options
      ::Settings::Authentication::NEW_USER_STATUSES.map do |status|
        [status.humanize, status]
      end
    end
  end
end
