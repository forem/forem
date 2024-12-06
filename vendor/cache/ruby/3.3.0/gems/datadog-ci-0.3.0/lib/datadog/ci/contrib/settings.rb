require "datadog/core/configuration/base"

module Datadog
  module CI
    module Contrib
      # Common settings for all integrations
      # @public_api
      class Settings
        include Core::Configuration::Base

        option :enabled, default: true
        option :service_name
        option :operation_name

        def configure(options = {})
          self.class.options.each do |name, _value|
            self[name] = options[name] if options.key?(name)
          end

          yield(self) if block_given?
        end

        def [](name)
          respond_to?(name) ? send(name) : get_option(name)
        end

        def []=(name, value)
          respond_to?("#{name}=") ? send("#{name}=", value) : set_option(name, value)
        end
      end
    end
  end
end
