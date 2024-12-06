module I18n
  module JS
    # When using `safe_gem_check` to check for a pre-release version of gem,
    # we need to specify pre-release version suffix in version constraint
    module Dependencies
      class << self
        def rails?
          defined?(Rails) && Rails.respond_to?(:version)
        end

        def sprockets_rails_v2_plus?
          safe_gem_check("sprockets-rails", ">= 2")
        end

        # This cannot be called at class definition time
        # Since not all libraries are loaded
        #
        # Call this in an initializer
        def using_asset_pipeline?
          assets_pipeline_available =
            (rails3? || rails4? || rails5? || rails6? || rails7?) &&
            Rails.respond_to?(:application) &&
            Rails.application.config.respond_to?(:assets)
          rails3_assets_enabled =
            rails3? &&
            assets_pipeline_available &&
            Rails.application.config.assets.enabled != false

          assets_pipeline_available && (rails4? || rails5? || rails6? || rails7? || rails3_assets_enabled)
        end

        private

        def rails3?
          rails? && Rails.version.to_i == 3
        end

        def rails4?
          rails? && Rails.version.to_i == 4
        end

        def rails5?
          rails? && Rails.version.to_i == 5
        end

        def rails6?
          rails? && Rails.version.to_i == 6
        end
        
        def rails7?
          rails? && Rails.version.to_i == 7
        end

        def safe_gem_check(*args)
          if Gem::Specification.respond_to?(:find_by_name)
            Gem::Specification.find_by_name(*args)
          elsif Gem.respond_to?(:available?)
            Gem.available?(*args)
          end
        rescue Gem::LoadError
          false
        end

      end
    end
  end
end
