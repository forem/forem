module InlineSvg::TransformPipeline
  module Transformations
    class NoComment < Transformation
      def transform(doc)
        with_svg(doc) do |svg|
          svg.xpath("//comment()").each do |comment|
            comment.remove
          end
        end
      end
    end
  end
end
