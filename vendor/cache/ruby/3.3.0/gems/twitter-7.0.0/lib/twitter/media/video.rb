require 'memoizable'
require 'twitter/identity'
require 'twitter/media/video_info'

module Twitter
  module Media
    class Video < Twitter::Identity
      include Memoizable

      # @return [Array<Integer>]
      attr_reader :indices

      # @return [String]
      attr_reader :type

      display_uri_attr_reader
      uri_attr_reader :expanded_uri, :media_uri, :media_uri_https, :uri

      # Returns an array of photo sizes
      #
      # @return [Array<Twitter::Size>]
      def sizes
        @attrs.fetch(:sizes, []).each_with_object({}) do |(key, value), object|
          object[key] = Size.new(value)
        end
      end
      memoize :sizes

      # Returns video info
      #
      # @return [Twitter::Media::VideoInfo]
      def video_info
        VideoInfo.new(@attrs[:video_info]) unless @attrs[:video_info].nil?
      end
      memoize :video_info
    end
  end
end
