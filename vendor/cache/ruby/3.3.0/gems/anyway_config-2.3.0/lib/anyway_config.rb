# frozen_string_literal: true

require "ruby-next"

require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path(transpile: true)

require "anyway/version"

require "anyway/ext/deep_dup"
require "anyway/ext/deep_freeze"
require "anyway/ext/hash"

require "anyway/utils/deep_merge"

require "anyway/settings"
require "anyway/tracing"
require "anyway/config"
require "anyway/auto_cast"
require "anyway/type_casting"
require "anyway/env"
require "anyway/loaders"
require "anyway/rbs"

module Anyway # :nodoc:
  class << self
    def env
      @env ||= ::Anyway::Env.new
    end

    def loaders
      @loaders ||= ::Anyway::Loaders::Registry.new
    end
  end

  # Configure default loaders
  loaders.append :yml, Loaders::YAML
  loaders.append :env, Loaders::Env
end

require "anyway/rails" if defined?(::Rails::VERSION)
require "anyway/testing" if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
