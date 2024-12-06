# frozen_string_literal: true

require "rails/generators"

module Anyway
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :configs_path, type: :string

      def copy_application_config
        template "application_config.rb", File.join(static_config_root, "application_config.rb")
      end

      def add_local_files_to_gitignore
        if File.exist?(File.join(destination_root, ".gitignore"))
          append_to_file ".gitignore", "\n/config/*.local.yml\n/config/credentials/local.*\n"
        end
      end

      # rubocop:disable Layout/HeredocIndentation
      def add_setup_autoload_to_config
        maybe_comment_indented = default_configs_path? ? "    # " : "    "
        inject_into_file "config/application.rb", after: %r{< Rails::Application\n} do
          <<-RUBY
    # Configure the path for configuration classes that should be used before initialization
    # NOTE: path should be relative to the project root (Rails.root)
#{maybe_comment_indented}config.anyway_config.autoload_static_config_path = "#{static_config_root}"
#{maybe_comment_indented.sub(/\s+$/, "")}
          RUBY
        end
      end
      # rubocop:enable Layout/HeredocIndentation

      private

      def static_config_root
        options[:configs_path] || Anyway::Settings.autoload_static_config_path || Anyway::DEFAULT_CONFIGS_PATH
      end

      def default_configs_path?
        static_config_root == (Anyway::Settings.autoload_static_config_path || Anyway::DEFAULT_CONFIGS_PATH)
      end
    end
  end
end
