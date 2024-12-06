require "inline_svg/version"
require "inline_svg/action_view/helpers"
require "inline_svg/asset_file"
require "inline_svg/cached_asset_file"
require "inline_svg/finds_asset_paths"
require "inline_svg/propshaft_asset_finder"
require "inline_svg/static_asset_finder"
require "inline_svg/webpack_asset_finder"
require "inline_svg/transform_pipeline"
require "inline_svg/io_resource"

require "inline_svg/railtie" if defined?(Rails)
require 'active_support'
require 'active_support/core_ext/string'
require 'nokogiri'

module InlineSvg
  class Configuration
    class Invalid < ArgumentError; end

    attr_reader :asset_file, :asset_finder, :custom_transformations, :svg_not_found_css_class

    def initialize
      @custom_transformations = {}
      @asset_file = InlineSvg::AssetFile
      @svg_not_found_css_class = nil
      @raise_on_file_not_found = false
    end

    def asset_file=(custom_asset_file)
      begin
        method = custom_asset_file.method(:named)
        if method.arity == 1
          @asset_file = custom_asset_file
        else
          raise InlineSvg::Configuration::Invalid.new("asset_file should implement the #named method with arity 1")
        end
      rescue NameError
        raise InlineSvg::Configuration::Invalid.new("asset_file should implement the #named method")
      end
    end

    def asset_finder=(finder)
      @asset_finder = if finder.respond_to?(:find_asset)
                        finder
                      elsif finder.class.name == "Propshaft::Assembly"
                        InlineSvg::PropshaftAssetFinder
                      else
                        # fallback to a naive static asset finder
                        # (sprokects >= 3.0 && config.assets.precompile = false
                        # See: https://github.com/jamesmartin/inline_svg/issues/25
                        InlineSvg::StaticAssetFinder
                      end
      asset_finder
    end

    def svg_not_found_css_class=(css_class)
      if css_class.present? && css_class.is_a?(String)
        @svg_not_found_css_class = css_class
      end
    end

    def add_custom_transformation(options)
      if incompatible_transformation?(options.fetch(:transform))
        raise InlineSvg::Configuration::Invalid.new("#{options.fetch(:transform)} should implement the .create_with_value and #transform methods")
      end
      @custom_transformations.merge!(Hash[ *[options.fetch(:attribute, :no_attribute), options] ])
    end

    def raise_on_file_not_found=(value)
      @raise_on_file_not_found = value
    end

    def raise_on_file_not_found?
      !!@raise_on_file_not_found
    end

    private

    def incompatible_transformation?(klass)
      !klass.is_a?(Class) || !klass.respond_to?(:create_with_value) || !klass.instance_methods.include?(:transform)
    end

  end

  @configuration = InlineSvg::Configuration.new

  class << self
    attr_reader :configuration

    def configure
      if block_given?
        yield configuration
      else
        raise InlineSvg::Configuration::Invalid.new('Please set configuration options with a block')
      end
    end

    def reset_configuration!
      @configuration = InlineSvg::Configuration.new
    end
  end
end
