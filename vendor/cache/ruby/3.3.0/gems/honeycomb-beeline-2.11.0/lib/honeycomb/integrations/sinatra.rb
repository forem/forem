# frozen_string_literal: true

require "sinatra"
require "honeycomb/integrations/rack"
require "honeycomb/integrations/warden"

module Honeycomb
  # Sinatra specific methods for building middleware
  module Sinatra
    def add_package_information(env)
      yield "meta.package", "sinatra"
      yield "meta.package_version", ::Sinatra::VERSION

      yield "request.route", env["sinatra.route"]
    end

    # Sinatra middleware
    class Middleware
      include Rack
      include Warden
      include Sinatra
    end
  end
end
