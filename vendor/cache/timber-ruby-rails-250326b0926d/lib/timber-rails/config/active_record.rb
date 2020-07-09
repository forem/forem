require "timber-rails/active_record"

module Timber
  class Config
    # Convenience module for accessing the various `Timber::Integrations::*` classes
    # through the {Timber::Config} object. Timber couples configuration with the class
    # responsible for implementing it. This provides for a tighter design, but also
    # requires the user to understand and access the various classes. This module aims
    # to provide a simple ruby-like configuration interface for internal Timber classes.
    #
    # For example:
    #
    #     config = Timber::Config.instance
    #     config.integrations.active_record.silence = true
    module Integrations
      extend self

      # Convenience method for accessing the {Timber::Integrations::ActiveRecord} class
      # specific configuration.
      #
      # @example
      #   config = Timber::Config.instance
      #   config.integrations.active_record.silence = true
      def active_record
        Timber::Integrations::ActiveRecord
      end
    end
  end
end
