module InlineSvg::TransformPipeline::Transformations
  class AriaHiddenAttribute < Transformation
    def transform(doc)
      with_svg(doc) do |svg|
        svg["aria-hidden"] = self.value
      end
    end
  end
end
