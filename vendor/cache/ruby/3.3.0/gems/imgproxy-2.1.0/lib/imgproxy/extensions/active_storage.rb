module Imgproxy
  module Extensions
    # Extension for ActiveStorage
    # @see Imgproxy.extend_active_storage!
    module ActiveStorage
      # Returns imgproxy URL for an attachment
      #
      # @return [String]
      # @param options [Hash, Imgproxy::Builder]
      # @see Imgproxy.url_for
      def imgproxy_url(options = {})
        return options.url_for(self) if options.is_a?(Imgproxy::Builder)
        Imgproxy.url_for(self, options)
      end

      # Returns imgproxy info URL for an attachment
      #
      # @return [String]
      # @param options [Hash, Imgproxy::Builder]
      # @see Imgproxy.info_url_for
      def imgproxy_info_url(options = {})
        return options.info_url_for(self) if options.is_a?(Imgproxy::Builder)
        Imgproxy.info_url_for(self, options)
      end
    end
  end
end
