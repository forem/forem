require 'memoizable'
require 'twitter/variant'

module Twitter
  module Media
    class VideoInfo < Twitter::Base
      include Memoizable

      # @return [Array<Integer]
      attr_reader :aspect_ratio

      # @return [Integer]
      attr_reader :duration_millis

      # Returns an array of video variants
      #
      # @return [Array<Twitter::Variant>]
      def variants
        @attrs.fetch(:variants, []).collect do |variant|
          Variant.new(variant)
        end
      end
      memoize :variants
    end
  end
end
