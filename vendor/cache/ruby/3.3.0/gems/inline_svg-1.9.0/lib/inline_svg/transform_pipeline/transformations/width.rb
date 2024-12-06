module InlineSvg::TransformPipeline::Transformations
  class Width < Transformation
    def transform(doc)
      with_svg(doc) do |svg|
        svg["width"] = self.value
      end
    end
  end
end
