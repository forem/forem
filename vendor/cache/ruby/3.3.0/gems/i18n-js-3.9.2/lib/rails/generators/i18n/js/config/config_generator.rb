module I18n
  module Js
    class ConfigGenerator < Rails::Generators::Base
      # Copied files come from templates folder
      source_root File.expand_path('../templates', __FILE__)

      # Generator desc
      desc <<-DESC
        Creates a default i18n-js.yml configuration file in your app's config
        folder. This file allows you to customize i18n:js:export rake task
        outputted files.
      DESC

      def copy_initializer_file
        copy_file "i18n-js.yml", "config/i18n-js.yml"
      end
    end
  end
end