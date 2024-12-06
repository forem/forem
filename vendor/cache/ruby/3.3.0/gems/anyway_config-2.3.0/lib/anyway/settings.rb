# frozen_string_literal: true

require "pathname"

module Anyway
  # Use Settings name to not confuse with Config.
  #
  # Settings contain the library-wide configuration.
  class Settings
    # Future encapsulates settings that will be introduced in the upcoming version
    # with the default values, which could break compatibility
    class Future
      class << self
        def setting(name, default_value)
          settings[name] = default_value

          define_method(name) do
            store[name]
          end

          define_method(:"#{name}=") do |val|
            store[name] = val
          end
        end

        def settings
          @settings ||= {}
        end
      end

      def initialize
        @store = {}
      end

      def use(*names)
        store.clear
        names.each { store[_1] = self.class.settings[_1] }
      end

      setting :unwrap_known_environments, true

      private

      attr_reader :store
    end

    class << self
      # Define whether to load data from
      # *.yml.local (or credentials/local.yml.enc)
      attr_accessor :use_local_files,
        :current_environment,
        :default_environmental_key,
        :known_environments

      # A proc returning a path to YML config file given the config name
      attr_reader :default_config_path

      def default_config_path=(val)
        if val.is_a?(Proc)
          @default_config_path = val
          return
        end

        val = val.to_s

        @default_config_path = ->(name) { File.join(val, "#{name}.yml") }
      end

      # Enable source tracing
      attr_accessor :tracing_enabled

      def future
        @future ||= Future.new
      end

      def app_root
        Pathname.new(Dir.pwd)
      end

      def default_environmental_key?
        !default_environmental_key.nil?
      end
    end

    # By default, use local files only in development (that's the purpose if the local files)
    self.use_local_files = (ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development")

    # By default, consider configs are stored in the ./config folder
    self.default_config_path = ->(name) { "./config/#{name}.yml" }

    # Tracing is enabled by default
    self.tracing_enabled = true
  end
end
