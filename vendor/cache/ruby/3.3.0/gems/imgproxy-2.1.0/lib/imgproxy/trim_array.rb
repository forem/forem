module Imgproxy
  # `Array.trim!` refinement
  module TrimArray
    refine Array do
      def trim!
        delete_at(-1) while !empty? && last.nil?
        self
      end
    end
  end
end
