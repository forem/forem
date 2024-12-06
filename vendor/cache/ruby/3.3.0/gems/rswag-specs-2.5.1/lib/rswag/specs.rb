# frozen_string_literal: true

require 'rspec/core'
require 'rswag/specs/example_group_helpers'
require 'rswag/specs/example_helpers'
require 'rswag/specs/configuration'
require 'rswag/specs/railtie' if defined?(Rails::Railtie)

module Rswag
  module Specs
    # Extend RSpec with a swagger-based DSL
    ::RSpec.configure do |c|
      c.add_setting :swagger_root
      c.add_setting :swagger_docs
      c.add_setting :swagger_dry_run
      c.add_setting :swagger_format
      c.extend ExampleGroupHelpers, type: :request
      c.include ExampleHelpers, type: :request
    end

    def self.config
      @config ||= Configuration.new(RSpec.configuration)
    end

    # Support Rails 3+ and RSpec 2+ (sigh!)
    RAILS_VERSION = Rails::VERSION::MAJOR
    RSPEC_VERSION = RSpec::Core::Version::STRING.split('.').first.to_i
  end
end
