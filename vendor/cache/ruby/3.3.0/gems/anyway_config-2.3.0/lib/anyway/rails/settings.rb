# frozen_string_literal: true

# Try to require zeitwerk
begin
  require "zeitwerk"
  require "active_support/dependencies/zeitwerk_integration"
rescue LoadError
end

module Anyway
  class Settings
    class << self
      attr_reader :autoload_static_config_path, :autoloader

      if defined?(::Zeitwerk)
        def autoload_static_config_path=(val)
          raise "Cannot setup autoloader after application has been initialized" if ::Rails.application.initialized?

          return unless ::Rails.root.join(val).exist?

          autoloader&.unload

          @autoload_static_config_path = val

          # See Rails 6 https://github.com/rails/rails/blob/8ab4fd12f18203b83d0f252db96d10731485ff6a/railties/lib/rails/autoloaders.rb#L10
          # and Rails 7 https://github.com/rails/rails/blob/5462fbd5de1900c1b1ce1c9dc11c1a2d8cdcd809/railties/lib/rails/autoloaders.rb#L15
          @autoloader = Zeitwerk::Loader.new.tap do |loader|
            loader.tag = "anyway.config"
            loader.inflector = defined?(ActiveSupport::Dependencies::ZeitwerkIntegration::Inflector) ? ActiveSupport::Dependencies::ZeitwerkIntegration::Inflector : ::Rails::Autoloaders::Inflector
            loader.push_dir(::Rails.root.join(val))
            loader.setup
          end
        end

        def cleanup_autoload_paths
          return unless autoload_static_config_path
          ActiveSupport::Dependencies.autoload_paths.delete(::Rails.root.join(autoload_static_config_path).to_s)
        end
      else
        def autoload_static_config_path=(val)
          if autoload_static_config_path
            old_path = ::Rails.root.join(autoload_static_config_path).to_s
            ActiveSupport::Dependencies.autoload_paths.delete(old_path)
            ::Rails.application.config.eager_load_paths.delete(old_path)
          end

          @autoload_static_config_path = val
          new_path = ::Rails.root.join(val).to_s
          ActiveSupport::Dependencies.autoload_paths << new_path
          ::Rails.application.config.eager_load_paths << new_path
        end

        def cleanup_autoload_paths
          :no_op
        end
      end

      def current_environment
        ::Rails.env.to_s
      end

      def app_root
        ::Rails.root
      end
    end

    self.default_config_path = ->(name) { ::Rails.root.join("config", "#{name}.yml") }
    self.known_environments = %w[test development production]
    # Don't try read defaults when no key defined
    self.default_environmental_key = nil
  end
end
