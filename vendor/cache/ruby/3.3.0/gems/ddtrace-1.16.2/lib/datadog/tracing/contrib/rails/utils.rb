# frozen_string_literal: true

require_relative '../analytics'

module Datadog
  module Tracing
    module Contrib
      module Rails
        # common utilities for Rails
        module Utils
          def self.app_name
            if ::Rails::VERSION::MAJOR >= 6
              ::Rails.application.class.module_parent_name.underscore
            elsif ::Rails::VERSION::MAJOR >= 4
              ::Rails.application.class.parent_name.underscore
            else
              ::Rails.application.class.to_s.underscore
            end
          end

          def self.railtie_supported?
            !!(defined?(::Rails::VERSION::MAJOR) && ::Rails::VERSION::MAJOR >= 3 && defined?(::Rails::Railtie))
          end
        end
      end
    end
  end
end
