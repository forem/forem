# frozen_string_literal: true

require "active_support/core_ext/hash/keys"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/class/attribute_accessors"

module BetterHtml
  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end

    def configure
      yield config if block_given?
    end
  end
end

require "better_html/version"
require "better_html/config"
require "better_html/helpers"
require "better_html/errors"
require "better_html/html_attributes"

require "better_html/railtie" if defined?(Rails)
