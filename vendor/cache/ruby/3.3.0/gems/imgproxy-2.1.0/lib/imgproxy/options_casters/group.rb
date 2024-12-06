require "imgproxy/trim_array"

module Imgproxy
  module OptionsCasters
    # Casts group of options and trim nils from the end
    class Group
      using TrimArray

      def initialize(extractors)
        @extractors = extractors
      end

      def cast(raw)
        values = @extractors.map do |key, extractor|
          extractor.cast(raw[key])
        end
        values.trim!
      end
    end
  end
end
