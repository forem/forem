# frozen_string_literal: true

require "rails/generators"

module Anyway
  module Generators
    class ConfigGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      class_option :yml, type: :boolean
      class_option :app, type: :boolean, default: false
      argument :parameters, type: :array, default: [], banner: "param1 param2"

      # check_class_collision suffix: "Config"

      def run_install_if_needed
        return if ::Rails.root.join(static_config_root, "application_config.rb").exist?
        generate "anyway:install"
      end

      def create_config
        template "config.rb", File.join(config_root, class_path, "#{file_name}_config.rb")
      end

      def create_yml
        create_yml = options.fetch(:yml) { yes?("Would you like to generate a #{file_name}.yml file?") }
        return unless create_yml
        template "config.yml", File.join("config", "#{file_name}.yml")
      end

      private

      def static_config_root
        Anyway::Settings.autoload_static_config_path || Anyway::DEFAULT_CONFIGS_PATH
      end

      def config_root
        if options[:app]
          "app/configs"
        else
          static_config_root
        end
      end
    end
  end
end
