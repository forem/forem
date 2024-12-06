if defined?(::Rails)
  require 'js_routes/engine'
end
require 'js_routes/version'
require "js_routes/configuration"
require "js_routes/instance"
require 'active_support/core_ext/string/indent'

module JsRoutes

  #
  # API
  #

  class << self
    def setup(&block)
      configuration.assign(&block)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def generate(**opts)
      Instance.new(opts).generate
    end

    def generate!(file_name = configuration.file, **opts)
      Instance.new(file: file_name, **opts).generate!
    end

    def definitions(**opts)
      generate(module_type: 'DTS', **opts)
    end

    def definitions!(file_name = nil, **opts)
      file_name ||= configuration.file&.sub(%r{(\.d)?\.(j|t)s\Z}, ".d.ts")
      generate!(file_name, module_type: 'DTS', **opts)
    end

    def json(string)
      ActiveSupport::JSON.encode(string)
    end
  end
  module Generators
  end
end

require "js_routes/middleware"
require "js_routes/generators/webpacker"
require "js_routes/generators/middleware"
