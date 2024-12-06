module InlineSvg::TransformPipeline::Transformations
  class PreserveAspectRatio < Transformation
    def transform(doc)
      with_svg(doc) do |svg|
        svg["preserveAspectRatio"] = self.value
      end
    end
  end
end
