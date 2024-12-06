# frozen_string_literal: true

require "singleton"

module I18n
  module JS
    # @api private
    module Private
      # Caching implementation for I18n::JS.config
      #
      # @api private
      class ConfigStore
        include Singleton

        def fetch
          return @config if @config

          yield.tap do |obj|
            raise ArgumentError, "unexpected falsy object from block" unless obj

            @config = obj
          end
        end

        def flush_cache
          @config = nil
        end
      end
    end
  end
end
