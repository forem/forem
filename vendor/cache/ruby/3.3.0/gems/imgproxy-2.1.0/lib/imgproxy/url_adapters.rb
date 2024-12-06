require "imgproxy/url_adapters/active_storage"
require "imgproxy/url_adapters/shrine"

module Imgproxy
  # URL adapters config. Allows to use this gem with ActiveStorage, Shrine, etc.
  #
  #   Imgproxy.configure do |config|
  #     config.url_adapters.add Imgproxy::UrlAdapters::ActiveStorage.new
  #   end
  #
  #   Imgproxy.url_for(user.avatar)
  class UrlAdapters
    class NotFound < StandardError; end
    class NotConfigured < StandardError; end

    # @return [Array] Currently added adapters
    attr_reader :adapters

    def initialize
      @adapters = []
    end

    # Add adapter to the end of the list
    # @return [Array]
    def add(adapter)
      adapters << adapter
    end

    # Add adapter to the beginning of the list
    # @return [Array]
    def prepend
      adapters.unshift(adapter)
    end

    # Remove all adapters from the list
    # @return [Array]
    def clear!
      @adapters = []
    end

    # Get URL for the provided image
    # @return [String]
    def url_of(image)
      return image if image.is_a? String
      return image.to_s if image.is_a? URI

      adapter = adapters.find { |a| a.applicable?(image) }

      return adapter.url(image) if adapter

      raise NotFound, "Can't found URL adapter for #{image.inspect}"
    end
  end
end
